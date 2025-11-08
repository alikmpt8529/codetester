import { contextBridge, ipcRenderer } from 'electron';
import { Violation } from '@shared/types';

export const electronAPI = {
  analyzeCode: (sourceCode: string, rules: string[]): Promise<Violation[]> =>
    ipcRenderer.invoke('code:analyze', sourceCode, rules),
};

// 'electronAPI'という名前で、安全にAPIをウィンドウオブジェクトに公開します。
contextBridge.exposeInMainWorld('electronAPI', electronAPI);

declare global {
  interface Window {
    electronAPI: typeof electronAPI;
  }
}