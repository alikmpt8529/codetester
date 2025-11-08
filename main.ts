import { app, BrowserWindow, ipcMain, session } from 'electron';
import * as path from 'path';

const isDev = process.env.NODE_ENV === 'development';

let mainWindow: BrowserWindow;

const createWindow = (): void => {
  // メインウィンドウを作成
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js') // Webpackが出力したPreloadスクリプト
    },
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    show: false
  });

  // 開発モードではlocalhost、本番ではファイルを読み込み
  if (isDev) {
    mainWindow.loadURL('http://localhost:3000');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, 'index.html'));
  }

  // ウィンドウの準備ができたら表示
  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  // ウィンドウが閉じられた時の処理
  mainWindow.on('closed', () => {
    mainWindow = null as any;
  });
};

// アプリケーションの準備ができた時
app.whenReady().then(() => {
  // 開発モードにおけるContent-Security-Policyの緩和
  if (isDev) {
    session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
      callback({
        responseHeaders: {
          ...details.responseHeaders,
          'Content-Security-Policy': ["script-src 'self' 'unsafe-inline' http://localhost:3000; style-src 'self' 'unsafe-inline';"],
        },
      });
    });
  }
  createWindow();

  app.on('activate', () => {
    // macOSでDockアイコンがクリックされた時
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

// すべてのウィンドウが閉じられた時
app.on('window-all-closed', () => {
  // macOS以外では完全にアプリを終了
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// セキュリティ: 新しいウィンドウの作成を制限
app.on('web-contents-created', (_event, contents) => {
  contents.setWindowOpenHandler(() => ({ action: 'deny' }));
});

// IPC通信のハンドラーをここに追加予定
ipcMain.handle('app:getVersion', () => {
  return app.getVersion();
});

export { mainWindow };