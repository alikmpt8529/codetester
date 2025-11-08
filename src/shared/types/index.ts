// 共通の型定義

export interface FileInfo {
  path: string;
  name: string;
  size: number;
  encoding: string;
  lastModified: Date;
}

export interface UploadedFile {
  id: string;
  type: 'primary-rules' | 'secondary-rules' | 'source-code';
  originalName: string;
  path: string;
  size: number;
  encoding: string;
  uploadedAt: Date;
  content?: string;
}

export interface Rule {
  id: string;
  description: string;
  pattern: RegExp | string;
  severity: 'error' | 'warning' | 'info';
  category: string;
}

export interface ParsedRules {
  rules: Rule[];
  metadata: RuleMetadata;
  assignments?: Assignment[];
}

export interface RuleMetadata {
  version?: string;
  author?: string;
  description?: string;
  createdAt?: Date;
}

export interface Assignment {
  id: number;
  title: string;
  description: string;
  template: string;
  requirements: string[];
}

export interface Violation {
  ruleId: string;
  line: number;
  column: number;
  message: string;
  severity: 'error' | 'warning' | 'info';
  context: string;
  suggestion?: string;
}

export interface AnalysisResult {
  violations: Violation[];
  summary: AnalysisSummary;
  correctedCode?: string;
}

export interface AnalysisSummary {
  totalViolations: number;
  errorCount: number;
  warningCount: number;
  infoCount: number;
  linesAnalyzed: number;
  processingTime: number;
}

export interface AnalysisSession {
  id: string;
  createdAt: Date;
  files: UploadedFile[];
  rules: ParsedRules[];
  result?: AnalysisResult;
  status: 'pending' | 'analyzing' | 'completed' | 'error';
}

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
}

export interface AppConfiguration {
  ui: {
    theme: 'light' | 'dark' | 'system';
    language: 'ja' | 'en';
    showProgressDetails: boolean;
  };
  analysis: {
    timeoutSeconds: number;
    maxFileSize: number;
    enableCache: boolean;
  };
  export: {
    defaultFormat: 'txt' | 'html';
    includeLineNumbers: boolean;
    includeContext: boolean;
  };
}