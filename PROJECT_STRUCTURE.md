# プロジェクト構造

## ディレクトリ構成

```
coding-rule-checker/
├── package.json
├── electron-builder.json
├── README.md
├── src/
│   ├── main/                    # Electronメインプロセス
│   │   ├── main.js
│   │   ├── preload.js
│   │   └── menu.js
│   ├── renderer/                # レンダラープロセス (React)
│   │   ├── components/
│   │   │   ├── FileUploader.jsx
│   │   │   ├── RuleChecker.jsx
│   │   │   ├── ResultViewer.jsx
│   │   │   └── ProgressBar.jsx
│   │   ├── pages/
│   │   │   ├── MainPage.jsx
│   │   │   └── SettingsPage.jsx
│   │   ├── utils/
│   │   │   ├── fileHandler.js
│   │   │   └── platformUtils.js
│   │   ├── App.jsx
│   │   └── index.js
│   ├── shared/                  # 共通ユーティリティ
│   │   ├── constants.js
│   │   ├── checker/
│   │   │   ├── ruleParser.js
│   │   │   ├── codeAnalyzer.js
│   │   │   └── violationDetector.js
│   │   └── utils/
│   │       ├── fileUtils.js
│   │       └── encodingDetector.js
│   └── workers/                 # ワーカープロセス
│       └── checker-worker.js
├── assets/                      # アプリケーションアセット
│   ├── icons/
│   │   ├── icon.icns           # Mac用アイコン
│   │   └── icon.ico            # Windows用アイコン
│   └── samples/                # サンプルファイル
│       ├── sample-rules.txt
│       └── sample-code.c
├── locales/                     # 国際化ファイル
│   ├── ja.json
│   └── en.json
├── build/                       # ビルド設定
│   ├── notarize.js             # Mac公証用
│   └── installer.nsh           # Windows インストーラー設定
└── dist/                        # ビルド出力
    ├── mac/
    └── win/
```

## 主要ファイルの役割

### メインプロセス (src/main/)
- **main.js**: アプリケーションのエントリーポイント
- **preload.js**: レンダラープロセスとの安全な通信
- **menu.js**: プラットフォーム別メニュー設定

### レンダラープロセス (src/renderer/)
- **components/**: 再利用可能なUIコンポーネント
- **pages/**: ページレベルのコンポーネント
- **utils/**: フロントエンド用ユーティリティ

### 共通モジュール (src/shared/)
- **checker/**: コーディング規約チェックのコアロジック
- **utils/**: プラットフォーム共通のユーティリティ

### ワーカー (src/workers/)
- **checker-worker.js**: 重い処理を別スレッドで実行

## 設定ファイル

### package.json
```json
{
  "name": "coding-rule-checker",
  "version": "1.0.0",
  "description": "C言語コーディング規約チェッカー",
  "main": "src/main/main.js",
  "scripts": {
    "start": "electron .",
    "dev": "concurrently \"npm run dev:renderer\" \"npm run dev:main\"",
    "dev:renderer": "webpack serve --config webpack.renderer.js",
    "dev:main": "electron . --inspect=5858",
    "build": "npm run build:renderer && npm run build:main",
    "build:renderer": "webpack --config webpack.renderer.js --mode production",
    "build:main": "webpack --config webpack.main.js --mode production",
    "dist": "electron-builder",
    "dist:mac": "electron-builder --mac",
    "dist:win": "electron-builder --win",
    "test": "jest",
    "test:e2e": "spectron"
  },
  "dependencies": {
    "electron": "^latest",
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "iconv-lite": "^0.6.3",
    "chardet": "^1.4.0"
  },
  "devDependencies": {
    "electron-builder": "^latest",
    "webpack": "^5.0.0",
    "@babel/core": "^7.0.0",
    "jest": "^29.0.0",
    "spectron": "^latest"
  }
}
```

### electron-builder.json
```json
{
  "appId": "com.example.coding-rule-checker",
  "productName": "Coding Rule Checker",
  "directories": {
    "output": "dist"
  },
  "files": [
    "src/**/*",
    "assets/**/*",
    "locales/**/*",
    "package.json"
  ],
  "mac": {
    "category": "public.app-category.developer-tools",
    "icon": "assets/icons/icon.icns",
    "target": [
      {
        "target": "dmg",
        "arch": ["x64", "arm64"]
      }
    ],
    "hardenedRuntime": true,
    "entitlements": "build/entitlements.mac.plist"
  },
  "win": {
    "icon": "assets/icons/icon.ico",
    "target": [
      {
        "target": "nsis",
        "arch": ["x64", "ia32"]
      }
    ]
  },
  "nsis": {
    "oneClick": false,
    "allowToChangeInstallationDirectory": true
  }
}
```