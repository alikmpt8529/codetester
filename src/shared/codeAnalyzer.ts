import { Violation } from '@shared/types';

/**
 * C言語のソースコードを解析し、コーディング規約違反を検出する
 * @param sourceCode 解析対象のC言語ソースコード
 * @param rules 適用するコーディング規約のリスト
 * @returns 検出された違反のリスト
 */
export const analyzeCCode = (sourceCode: string, rules: string[]): Violation[] => {
  console.log('Analyzing C code...');
  console.log('Rules:', rules);

  // TODO: ここに本格的な解析ロジックを実装します。
  // 現時点では、ダミーの違反情報を返します。
  const violations: Violation[] = [];

  if (sourceCode.includes('magic_number')) {
    violations.push({
      line: 10,
      rule: 'No Magic Numbers',
      message: 'コード内にマジックナンバーが検出されました。定数を使用してください。',
    });
  }

  return violations;
};