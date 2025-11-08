import { parentPort, workerData } from 'worker_threads';
import { AnalysisResult, ParsedRules } from '../shared/types';

// ワーカープロセスでの重い解析処理
// 現在は基本的な構造のみ実装、後で詳細な解析ロジックを追加

interface WorkerData {
  sourceCode: string;
  rules: ParsedRules[];
  sessionId: string;
}

const analyzeCode = (sourceCode: string, rules: ParsedRules[]): AnalysisResult => {
  const startTime = Date.now();
  
  // プログレス報告
  if (parentPort) {
    parentPort.postMessage({
      type: 'progress',
      progress: 0,
      message: '解析を開始しています...'
    });
  }
  
  // 基本的な解析処理（後で詳細実装）
  const violations: any[] = [];
  const lines = sourceCode.split('\n');
  
  // 簡単な例: インデントチェック
  lines.forEach((line, index) => {
    if (parentPort) {
      parentPort.postMessage({
        type: 'progress',
        progress: Math.round((index / lines.length) * 100),
        message: `行 ${index + 1} を解析中...`
      });
    }
    
    // 基本的なルールチェック例
    if (line.trim().length > 0 && line.startsWith(' ') && !line.startsWith('    ')) {
      violations.push({
        ruleId: 'indent-rule',
        line: index + 1,
        column: 1,
        message: 'インデントは4スペースで統一してください',
        severity: 'warning',
        context: line.trim()
      });
    }
  });
  
  const endTime = Date.now();
  
  const result: AnalysisResult = {
    violations,
    summary: {
      totalViolations: violations.length,
      errorCount: violations.filter(v => v.severity === 'error').length,
      warningCount: violations.filter(v => v.severity === 'warning').length,
      infoCount: violations.filter(v => v.severity === 'info').length,
      linesAnalyzed: lines.length,
      processingTime: endTime - startTime
    }
  };
  
  return result;
};

// メインスレッドからのデータを受信
if (workerData) {
  try {
    const { sourceCode, rules, sessionId } = workerData as WorkerData;
    
    const result = analyzeCode(sourceCode, rules);
    
    // 結果をメインスレッドに送信
    if (parentPort) {
      parentPort.postMessage({
        type: 'result',
        result,
        sessionId
      });
    }
  } catch (error) {
    // エラーをメインスレッドに送信
    if (parentPort) {
      parentPort.postMessage({
        type: 'error',
        error: error instanceof Error ? error.message : 'Unknown error',
        sessionId: workerData?.sessionId
      });
    }
  }
}