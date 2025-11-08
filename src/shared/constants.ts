// アプリケーション定数

export const FILE_CONSTRAINTS = {
  MAX_FILE_SIZE: 10 * 1024 * 1024, // 10MB
  ALLOWED_RULE_EXTENSIONS: ['.txt'],
  ALLOWED_SOURCE_EXTENSIONS: ['.c'],
  SUPPORTED_ENCODINGS: ['utf-8', 'shift_jis', 'euc-jp', 'iso-2022-jp']
} as const;

export const ANALYSIS_SETTINGS = {
  DEFAULT_TIMEOUT: 30000, // 30秒
  PROGRESS_UPDATE_INTERVAL: 100, // 100ms
  MAX_VIOLATIONS_DISPLAY: 1000,
  WORKER_TIMEOUT: 25000 // 25秒（メインタイムアウトより短く）
} as const;

export const UI_CONSTANTS = {
  MIN_WINDOW_WIDTH: 800,
  MIN_WINDOW_HEIGHT: 600,
  DEFAULT_WINDOW_WIDTH: 1200,
  DEFAULT_WINDOW_HEIGHT: 800
} as const;

export const ERROR_MESSAGES = {
  FILE_TOO_LARGE: 'ファイルサイズが10MBを超えています',
  INVALID_FILE_TYPE: '対応していないファイル形式です',
  EMPTY_FILE: 'ファイルが空です',
  ENCODING_ERROR: 'ファイルの文字エンコーディングを検出できません',
  ANALYSIS_TIMEOUT: '解析がタイムアウトしました',
  ANALYSIS_ERROR: '解析中にエラーが発生しました',
  FILE_READ_ERROR: 'ファイルの読み込みに失敗しました',
  FILE_SAVE_ERROR: 'ファイルの保存に失敗しました'
} as const;

export const SUCCESS_MESSAGES = {
  FILE_UPLOADED: 'ファイルのアップロードが完了しました',
  ANALYSIS_COMPLETE: '解析が完了しました',
  FILE_SAVED: 'ファイルの保存が完了しました',
  NO_VIOLATIONS: 'コーディング規約違反は見つかりませんでした'
} as const;