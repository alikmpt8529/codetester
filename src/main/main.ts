import { app, BrowserWindow, ipcMain } from 'electron';
import path from 'path';
import { analyzeCCode } from '@shared/codeAnalyzer';

const createWindow = () => {
  const mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:3000');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, 'index.html'));
  }
};

app.whenReady().then(() => {
  // IPCハンドラ: レンダラーからの解析要求を処理
  ipcMain.handle('code:analyze', (event, sourceCode, rules) => {
    return analyzeCCode(sourceCode, rules);
  });

  createWindow();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});