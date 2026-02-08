
import React, { useEffect, useRef } from 'react';

interface VisualizerProps {
  isActive: boolean;
  isListening: boolean;
}

const Visualizer: React.FC<VisualizerProps> = ({ isActive, isListening }) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (!canvasRef.current) return;
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animationFrame: number;
    let offset = 0;

    const render = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const width = canvas.width;
      const height = canvas.height;
      
      const speed = isActive ? 0.05 : isListening ? 0.02 : 0;
      const amplitude = isActive ? 40 : isListening ? 10 : 2;
      
      ctx.beginPath();
      ctx.strokeStyle = isActive ? '#fb7185' : '#60a5fa';
      ctx.lineWidth = 3;
      ctx.lineCap = 'round';

      for (let x = 0; x < width; x++) {
        const y = height / 2 + Math.sin(x * 0.02 + offset) * amplitude;
        if (x === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }

      ctx.stroke();
      offset += speed;
      animationFrame = requestAnimationFrame(render);
    };

    render();
    return () => cancelAnimationFrame(animationFrame);
  }, [isActive, isListening]);

  return (
    <canvas 
      ref={canvasRef} 
      width={400} 
      height={150} 
      className="w-full max-w-md mx-auto rounded-xl"
    />
  );
};

export default Visualizer;
