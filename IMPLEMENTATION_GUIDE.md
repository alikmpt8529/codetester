# 実装ガイド

## 開発環境セットアップ

### 必要なツール
```bash
# Node.js (v16以上)
# npm または yarn
# Git

# プロジェクト初期化
npm init -y
npm install electron react react-dom
npm install -D electron-builder webpack babel-loader @babel/core @babel/preset-react
```

## 段階的実装計画

### Phase 1: 基本フレームワーク構築
1. Electronアプリケーションの基本構造
2. React UIの基本レイアウト
3. ファイルアップロード機能

### Phase 2: コア機能実装
1. コーディング規約パーサー
2. Cソースコード解析エンジン
3. 違反検出ロジック

### Phase 3: UI/UX改善
1. プログレスバーとローディング
2. エラーハンドリング
3. 結果表示の改善

### Phase 4: プラットフォーム最適化
1. Mac/Windows固有の機能
2. ネイティブメニュー
3. ファイル関連付け

### Phase 5: 配布準備
1. アプリケーション署名
2. インストーラー作成
3. 自動更新機能

## 重要な実装ポイント

### 1. セキュリティ
```javascript
// preload.js - 安全なAPI公開
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  openFile: () => ipcRenderer.invoke('dialog:openFile'),
  saveFile: (content) => ipcRenderer.invoke('dialog:saveFile', content),
  checkRules: (data) => ipcRenderer.invoke('checker:analyze', data)
});
```

### 2. パフォーマンス
```javascript
// ワーカーでの重い処理
// checker-worker.js
const { parentPort, workerData } = require('worker_threads');

const analyzeCode = (sourceCode, rules) => {
  // 重いチェック処理
  const violations = performAnalysis(sourceCode, rules);
  return violations;
};

parentPort.postMessage(analyzeCode(workerData.sourceCode, workerData.rules));
```

### 3. エラーハンドリング
```javascript
// グローバルエラーハンドラー
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  // ログファイルに記録
  logError(error);
});

// レンダラープロセスでのエラー境界
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    console.error('React Error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return <h1>エラーが発生しました。</h1>;
    }
    return this.props.children;
  }
}
```

## テスト戦略

### 単体テスト
```javascript
// __tests__/ruleParser.test.js
const { parseRules } = require('../src/shared/checker/ruleParser');

describe('Rule Parser', () => {
  test('should parse basic coding rules', () => {
    const ruleText = 'インデントは4スペース\n関数名はキャメルケース';
    const rules = parseRules(ruleText);
    expect(rules).toHaveLength(2);
  });
});
```

### E2Eテスト
```javascript
// e2e/app.test.js
const { Application } = require('spectron');

describe('Application', () => {
  beforeEach(async () => {
    this.app = new Application({
      path: electronPath,
      args: [path.join(__dirname, '..')]
    });
    await this.app.start();
  });

  afterEach(async () => {
    if (this.app && this.app.isRunning()) {
      await this.app.stop();
    }
  });

  test('should show initial window', async () => {
    const count = await this.app.client.getWindowCount();
    expect(count).toBe(1);
  });
});
```

## CI/CD設定

### GitHub Actions
```yaml
# .github/workflows/build.yml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-mac:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm run build
      - run: npm run dist:mac
      - uses: actions/upload-artifact@v3
        with:
          name: mac-build
          path: dist/*.dmg

  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm run build
      - run: npm run dist:win
      - uses: actions/upload-artifact@v3
        with:
          name: windows-build
          path: dist/*.exe
```

## デバッグとトラブルシューティング

### 開発者ツール
```javascript
// main.js - 開発モードでDevToolsを開く
if (isDev) {
  mainWindow.webContents.openDevTools();
}

// デバッグ用ログ
const log = require('electron-log');
log.info('Application started');
```

### プラットフォーム固有の問題
```javascript
// プラットフォーム検出
const platform = process.platform;
const isWin = platform === 'win32';
const isMac = platform === 'darwin';

// プラットフォーム別の処理
if (isMac) {
  // Mac固有の処理
  app.dock.setIcon(path.join(__dirname, 'assets/dock-icon.png'));
} else if (isWin) {
  // Windows固有の処理
  app.setAppUserModelId('com.example.coding-rule-checker');
}
```

## パフォーマンス監視

### メモリ使用量監視
```javascript
const monitorMemory = () => {
  const usage = process.memoryUsage();
  console.log('Memory Usage:', {
    rss: Math.round(usage.rss / 1024 / 1024) + ' MB',
    heapTotal: Math.round(usage.heapTotal / 1024 / 1024) + ' MB',
    heapUsed: Math.round(usage.heapUsed / 1024 / 1024) + ' MB'
  });
};

setInterval(monitorMemory, 30000); // 30秒ごとに監視
```