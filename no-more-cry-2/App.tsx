
import React, { useState, useEffect, useRef, useCallback } from 'react';
import { GoogleGenAI, Modality, LiveServerMessage } from '@google/genai';
import { AppStatus, TranscriptionEntry } from './types';
import { decode, encode, decodeAudioData, createPcmBlob } from './services/audioUtils';
import Visualizer from './components/Visualizer';

const SAMPLE_RATE_IN = 16000;
const SAMPLE_RATE_OUT = 24000;
const SYSTEM_PROMPT = `
You are a warm, gentle, and musical nanny AI designed to soothe crying babies. 
When you detect distress, your goal is to immediately offer comfort.
Rules:
1. Use a soft, melodic, and rhythmic voice.
2. Hum gentle lullabies or tell very short, calming stories about fluffy clouds and sleepy animals.
3. Keep sentences short and repetitive (like "It's okay, little one", "Shhh, I am here").
4. If the baby keeps crying, try a different approach: gentle singing or mimicking a heartbeat sound.
5. Do not stop until the environment becomes quiet.
`;

type AudioSourceType = 'microphone' | 'system';

const App: React.FC = () => {
  const [status, setStatus] = useState<AppStatus>(AppStatus.IDLE);
  const [history, setHistory] = useState<TranscriptionEntry[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [threshold, setThreshold] = useState<number>(0.15);
  const [currentVolume, setCurrentVolume] = useState<number>(0);
  const [audioSource, setAudioSource] = useState<AudioSourceType>('microphone');
  const [isMobile, setIsMobile] = useState(false);
  
  const inputAudioCtxRef = useRef<AudioContext | null>(null);
  const outputAudioCtxRef = useRef<AudioContext | null>(null);
  const nextStartTimeRef = useRef<number>(0);
  const sourcesRef = useRef<Set<AudioBufferSourceNode>>(new Set());
  const sessionRef = useRef<any>(null);
  const monitorIntervalRef = useRef<number | null>(null);
  const activeStreamRef = useRef<MediaStream | null>(null);

  useEffect(() => {
    // 简单的移动端检测
    setIsMobile(/iPhone|iPad|iPod|Android/i.test(navigator.userAgent));
  }, []);

  const stopAllAudio = useCallback(() => {
    sourcesRef.current.forEach(source => {
      try { source.stop(); } catch (e) {}
    });
    sourcesRef.current.clear();
    nextStartTimeRef.current = 0;
  }, []);

  const cleanupActiveStream = () => {
    if (activeStreamRef.current) {
      activeStreamRef.current.getTracks().forEach(track => track.stop());
      activeStreamRef.current = null;
    }
  };

  const startSession = useCallback(async (existingStream?: MediaStream) => {
    try {
      if (!process.env.API_KEY) throw new Error("API Key missing");
      const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
      
      if (!outputAudioCtxRef.current) {
        outputAudioCtxRef.current = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: SAMPLE_RATE_OUT });
      }

      const sessionPromise = ai.live.connect({
        model: 'gemini-2.5-flash-native-audio-preview-12-2025',
        config: {
          responseModalities: [Modality.AUDIO],
          speechConfig: {
            voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Kore' } },
          },
          systemInstruction: SYSTEM_PROMPT,
          outputAudioTranscription: {},
          inputAudioTranscription: {},
        },
        callbacks: {
          onopen: () => {
            console.log("Gemini session opened");
            setStatus(AppStatus.ACTIVE);
          },
          onmessage: async (message: LiveServerMessage) => {
            const audioData = message.serverContent?.modelTurn?.parts[0]?.inlineData?.data;
            if (audioData && outputAudioCtxRef.current) {
              const ctx = outputAudioCtxRef.current;
              nextStartTimeRef.current = Math.max(nextStartTimeRef.current, ctx.currentTime);
              const buffer = await decodeAudioData(decode(audioData), ctx, SAMPLE_RATE_OUT, 1);
              const source = ctx.createBufferSource();
              source.buffer = buffer;
              source.connect(ctx.destination);
              source.addEventListener('ended', () => sourcesRef.current.delete(source));
              source.start(nextStartTimeRef.current);
              nextStartTimeRef.current += buffer.duration;
              sourcesRef.current.add(source);
            }

            if (message.serverContent?.interrupted) {
              stopAllAudio();
            }

            if (message.serverContent?.inputTranscription || message.serverContent?.outputTranscription) {
              const text = message.serverContent.inputTranscription?.text || message.serverContent.outputTranscription?.text;
              if (text) {
                setHistory(prev => [...prev.slice(-10), { 
                  role: message.serverContent?.inputTranscription ? 'user' : 'ai', 
                  text, 
                  timestamp: Date.now() 
                }]);
              }
            }
          },
          onerror: (err) => {
            console.error("Gemini Error:", err);
            setError("Communication error. Please restart.");
            setStatus(AppStatus.ERROR);
          },
          onclose: () => {
            console.log("Gemini session closed");
            if (status === AppStatus.ACTIVE) setStatus(AppStatus.LISTENING);
          }
        }
      });

      sessionRef.current = await sessionPromise;

      let stream = existingStream;
      if (!stream) {
        stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      }
      
      if (!inputAudioCtxRef.current) {
        inputAudioCtxRef.current = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: SAMPLE_RATE_IN });
      }
      const source = inputAudioCtxRef.current.createMediaStreamSource(stream);
      const processor = inputAudioCtxRef.current.createScriptProcessor(4096, 1, 1);
      
      processor.onaudioprocess = (e) => {
        const inputData = e.inputBuffer.getChannelData(0);
        const pcmBlob = createPcmBlob(inputData);
        sessionRef.current?.sendRealtimeInput({ media: pcmBlob });
      };

      source.connect(processor);
      processor.connect(inputAudioCtxRef.current.destination);

    } catch (err: any) {
      setError(err.message || "Failed to connect to Gemini");
      setStatus(AppStatus.ERROR);
    }
  }, [status, stopAllAudio]);

  const startMonitoring = async () => {
    try {
      setError(null);
      setStatus(AppStatus.LISTENING);
      
      let stream: MediaStream;
      if (audioSource === 'system' && !isMobile) {
        // 请求系统/标签页音频
        stream = await (navigator.mediaDevices as any).getDisplayMedia({
          video: { displaySurface: "browser" },
          audio: true
        });
        // 确保获取到了音频轨道（有些用户可能只选择了视频没选音频）
        if (stream.getAudioTracks().length === 0) {
          stream.getTracks().forEach(t => t.stop());
          throw new Error("No system audio selected. Please enable 'Share audio'.");
        }
      } else {
        stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      }
      
      activeStreamRef.current = stream;
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const analyser = audioContext.createAnalyser();
      const microphone = audioContext.createMediaStreamSource(stream);
      microphone.connect(analyser);
      analyser.fftSize = 256;
      const dataArray = new Uint8Array(analyser.frequencyBinCount);

      const checkVolume = () => {
        analyser.getByteFrequencyData(dataArray);
        let sum = 0;
        for (let i = 0; i < dataArray.length; i++) sum += dataArray[i];
        const average = sum / dataArray.length / 255;
        setCurrentVolume(average);
        
        if (average > threshold) {
          console.log("Detection trigger met!");
          // 将当前流传递给 session 使用
          startSession(stream);
          audioContext.close();
          if (monitorIntervalRef.current) cancelAnimationFrame(monitorIntervalRef.current);
          return;
        }
        monitorIntervalRef.current = requestAnimationFrame(checkVolume);
      };
      monitorIntervalRef.current = requestAnimationFrame(checkVolume);
    } catch (err: any) {
      setError(err.message || "Permission denied.");
      setStatus(AppStatus.ERROR);
    }
  };

  const handleStop = () => {
    if (monitorIntervalRef.current) cancelAnimationFrame(monitorIntervalRef.current);
    stopAllAudio();
    sessionRef.current?.close();
    sessionRef.current = null;
    cleanupActiveStream();
    setStatus(AppStatus.IDLE);
    setCurrentVolume(0);
  };

  const toggleSource = () => {
    if (status !== AppStatus.IDLE) return;
    setAudioSource(prev => prev === 'microphone' ? 'system' : 'microphone');
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-4">
      <div className="text-center mb-6">
        <h1 className="text-4xl font-bold text-sky-600 mb-2">No More Cry</h1>
        <p className="text-sky-500/80">AI Soothing Companion</p>
      </div>

      <div className="w-full max-w-lg bg-white rounded-3xl shadow-2xl p-8 flex flex-col items-center relative overflow-hidden">
        {/* Status Badge */}
        <div className={`mb-4 px-4 py-1 rounded-full text-xs font-semibold uppercase tracking-wider transition-colors duration-500 ${
          status === AppStatus.IDLE ? 'bg-gray-100 text-gray-500' :
          status === AppStatus.LISTENING ? 'bg-yellow-100 text-yellow-600 animate-pulse' :
          status === AppStatus.ACTIVE ? 'bg-green-100 text-green-600' :
          'bg-red-100 text-red-600'
        }`}>
          {status === AppStatus.IDLE && 'Ready'}
          {status === AppStatus.LISTENING && 'Monitoring...'}
          {status === AppStatus.ACTIVE && 'Engaged'}
          {status === AppStatus.ERROR && 'Error'}
        </div>

        {/* Audio Source Selector (Computer Only) */}
        {!isMobile && status === AppStatus.IDLE && (
          <div className="flex bg-sky-50 p-1 rounded-xl mb-6 self-stretch">
            <button 
              onClick={() => setAudioSource('microphone')}
              className={`flex-1 py-2 px-3 rounded-lg text-xs font-bold transition-all flex items-center justify-center gap-2 ${audioSource === 'microphone' ? 'bg-white text-sky-600 shadow-sm' : 'text-sky-400'}`}
            >
              <span>🎤</span> Microphone
            </button>
            <button 
              onClick={() => setAudioSource('system')}
              className={`flex-1 py-2 px-3 rounded-lg text-xs font-bold transition-all flex items-center justify-center gap-2 ${audioSource === 'system' ? 'bg-white text-sky-600 shadow-sm' : 'text-sky-400'}`}
            >
              <span>💻</span> System Audio
            </button>
          </div>
        )}

        {/* Volume & Threshold Controls */}
        {(status === AppStatus.IDLE || status === AppStatus.LISTENING) && (
          <div className="w-full mb-6 px-6 py-4 bg-sky-50/50 rounded-2xl border border-sky-100/50">
            <div className="flex justify-between items-center mb-2">
              <span className="text-[10px] font-bold text-sky-700 uppercase">Threshold</span>
              <span className="text-[10px] font-mono text-sky-600">{Math.round(threshold * 100)}%</span>
            </div>
            <input 
              type="range" 
              min="0.01" 
              max="0.5" 
              step="0.01" 
              value={threshold} 
              onChange={(e) => setThreshold(parseFloat(e.target.value))}
              className="w-full h-1.5 bg-sky-200 rounded-lg appearance-none cursor-pointer accent-sky-500"
            />
            <div className="mt-4 flex items-center gap-3">
              <div className="text-[9px] text-sky-800/40 uppercase font-bold w-16">Input:</div>
              <div className="flex-1 h-1.5 bg-white rounded-full overflow-hidden border border-sky-100/30">
                <div 
                  className={`h-full transition-all duration-75 ${currentVolume > threshold ? 'bg-rose-400' : 'bg-sky-400'}`}
                  style={{ width: `${Math.min(currentVolume * 100 * 2, 100)}%` }}
                ></div>
              </div>
            </div>
          </div>
        )}

        <div className="relative mb-8 w-full flex justify-center">
          <div className={`w-32 h-32 rounded-full bg-sky-50 flex items-center justify-center border-4 border-white shadow-xl transition-all duration-700 ${status === AppStatus.ACTIVE ? 'scale-110 rotate-3 ring-4 ring-sky-100' : 'scale-100'}`}>
             <img 
               src={status === AppStatus.ACTIVE ? "https://picsum.photos/seed/nanny/200" : "https://picsum.photos/seed/calm/200"} 
               alt="AI Avatar" 
               className="w-full h-full object-cover rounded-full opacity-90"
             />
          </div>
          <div className="absolute -bottom-6 w-full px-12">
            <Visualizer isActive={status === AppStatus.ACTIVE} isListening={status === AppStatus.LISTENING} />
          </div>
        </div>

        <div className="w-full h-24 overflow-y-auto mb-6 text-center px-4 space-y-2 border-t border-sky-50 pt-6">
          {history.length === 0 && (
            <p className="text-gray-400 italic text-[11px]">
              {status === AppStatus.IDLE ? `Source: ${audioSource === 'microphone' ? 'Mic' : 'System'}` : 'Listening...'}
            </p>
          )}
          {history.map((entry, idx) => (
            <div key={idx} className={`text-[11px] leading-relaxed ${entry.role === 'ai' ? 'text-sky-600 font-semibold' : 'text-gray-400'}`}>
              {entry.role === 'ai' ? 'AI: ' : '👶: '} {entry.text}
            </div>
          ))}
        </div>

        <div className="flex gap-4">
          {status === AppStatus.IDLE || status === AppStatus.ERROR ? (
            <button 
              onClick={startMonitoring}
              className="bg-sky-500 hover:bg-sky-600 text-white px-10 py-3 rounded-2xl font-bold shadow-lg shadow-sky-200 transition-all hover:-translate-y-1 active:translate-y-0"
            >
              Start Monitoring
            </button>
          ) : (
            <button 
              onClick={handleStop}
              className="bg-white border-2 border-rose-400 text-rose-500 hover:bg-rose-50 px-10 py-3 rounded-2xl font-bold transition-all shadow-sm"
            >
              Stop Session
            </button>
          )}
        </div>

        {error && <div className="mt-4 p-2 bg-rose-50 rounded-lg text-[10px] text-rose-500 text-center max-w-xs">{error}</div>}
      </div>

      <div className="mt-8 text-center max-w-xs">
        <p className="text-[10px] text-sky-800/40 leading-relaxed italic">
          {audioSource === 'system' 
            ? "Tip: Playing a crying baby video on another tab? Make sure to check 'Share audio' in the popup!" 
            : "Tip: Place the device near the baby. Adjust threshold if it triggers too easily."}
        </p>
      </div>
    </div>
  );
};

export default App;
