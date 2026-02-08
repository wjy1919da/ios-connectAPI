
export enum AppStatus {
  IDLE = 'IDLE',
  LISTENING = 'LISTENING',
  ACTIVE = 'ACTIVE',
  ERROR = 'ERROR'
}

export interface TranscriptionEntry {
  role: 'user' | 'ai';
  text: string;
  timestamp: number;
}
