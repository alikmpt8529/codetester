# コーディング規約チェッカー - クロスプラットフォーム設計仕様

## 技術スタック選択

### 推奨アプローチ: Electron + React
- **Electron**: クロスプラットフォーム対応
- **React**: UI開発の効率性
- **Node.js**: バックエンド処理
- **TypeScript**: 型安全性とメンテナンス性

## プラットフォーム別対応

### Mac (macOS)
```
アプリケーション形式: .app
配布方法: .dmg
最小対応バージョン: macOS 10.15 (Catalina)
```

### Windows
```
アプリケーション形式: .exe
配布方法: .msi インストーラー
最小対応バージョン: Windows 10
```

## ファイルシステム対応

### パス区切り文字
```javascript
// クロスプラットフォーム対応
const path = require('path');
const filePath = path.join(baseDir, 'coding-rules', 'main.txt');
```

### ファイルダイアログ
```javascript
// Electronのdialog APIを使用
const { dialog } = require('electron');

// ファイル選択ダイアログ
const openFile = async () => {
  const result = await dialog.showOpenDialog({
    properties: ['openFile'],
    filters: [
      { name: 'Text Files', extensions: ['txt'] },
      { name: 'C Files', extensions: ['c'] }
    ]
  });
  return result.filePaths[0];
};
```

## UI/UX設計

### ネイティブルック&フィール
- **Mac**: macOSのHuman Interface Guidelines準拠
- **Windows**: Fluent Design System準拠

### ウィンドウ管理
```javascript
// プラットフォーム別ウィンドウ設定
const createWindow = () => {
  const win = new BrowserWindow({
    width: 1200,
    height: 800,
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    frame: process.platform !== 'darwin'
  });
};
```

## ファイル処理の最適化

### 文字エンコーディング対応
```javascript
const fs = require('fs');
const iconv = require('iconv-lite');

const readFileWithEncoding = (filePath) => {
  const buffer = fs.readFileSync(filePath);
  
  // 文字エンコーディング自動検出
  const encoding = detectEncoding(buffer);
  return iconv.decode(buffer, encoding);
};
```

### プラットフォーム別設定保存
```javascript
const os = require('os');
const path = require('path');

const getConfigPath = () => {
  switch (process.platform) {
    case 'darwin':
      return path.join(os.homedir(), 'Library', 'Application Support', 'CodingRuleChecker');
    case 'win32':
      return path.join(os.homedir(), 'AppData', 'Roaming', 'CodingRuleChecker');
    default:
      return path.join(os.homedir(), '.coding-rule-checker');
  }
};
```

## セキュリティ対策

### ファイルアクセス制限
```javascript
const path = require('path');

const validateFilePath = (filePath) => {
  const resolved = path.resolve(filePath);
  const allowed = path.resolve(process.cwd());
  
  if (!resolved.startsWith(allowed)) {
    throw new Error('不正なファイルパスです');
  }
};
```

### サンドボックス化
```javascript
// main.js
const win = new BrowserWindow({
  webSecurity: true,
  nodeIntegration: false,
  contextIsolation: true,
  preload: path.join(__dirname, 'preload.js')
});
```

## パフォーマンス最適化

### ワーカープロセス活用
```javascript
const { Worker } = require('worker_threads');

const checkCodingRules = (sourceCode, rules) => {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./checker-worker.js', {
      workerData: { sourceCode, rules }
    });
    
    worker.on('message', resolve);
    worker.on('error', reject);
  });
};
```

### メモリ管理
```javascript
// 大きなファイルのストリーム処理
const fs = require('fs');
const readline = require('readline');

const processLargeFile = async (filePath) => {
  const fileStream = fs.createReadStream(filePath);
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });
  
  for await (const line of rl) {
    // 行ごとに処理
  }
};
```

## 配布・インストール

### Mac配布
```json
// package.json
{
  "build": {
    "mac": {
      "category": "public.app-category.developer-tools",
      "target": [
        {
          "target": "dmg",
          "arch": ["x64", "arm64"]
        }
      ]
    }
  }
}
```

### Windows配布
```json
// package.json
{
  "build": {
    "win": {
      "target": [
        {
          "target": "nsis",
          "arch": ["x64", "ia32"]
        }
      ]
    }
  }
}
```

## 自動更新機能
```javascript
const { autoUpdater } = require('electron-updater');

// 起動時に更新チェック
app.whenReady().then(() => {
  autoUpdater.checkForUpdatesAndNotify();
});
```

## テスト戦略

### プラットフォーム別テスト
- **Mac**: GitHub Actions (macOS runner)
- **Windows**: GitHub Actions (Windows runner)
- **統合テスト**: 両プラットフォームでの動作確認

### E2Eテスト
```javascript
// Spectronを使用したE2Eテスト
const { Application } = require('spectron');

describe('Coding Rule Checker', () => {
  beforeEach(async () => {
    this.app = new Application({
      path: electronPath,
      args: [path.join(__dirname, '..')]
    });
    await this.app.start();
  });
});
```

## 国際化対応
```javascript
const i18n = require('i18next');

i18n.init({
  lng: app.getLocale(),
  resources: {
    ja: { translation: require('./locales/ja.json') },
    en: { translation: require('./locales/en.json') }
  }
});
```