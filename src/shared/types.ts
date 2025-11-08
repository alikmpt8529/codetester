/**
 * コーディング規約違反を表すオブジェクトの型
 */
export interface Violation {
  line: number; // 違反箇所の行番号
  rule: string; // 違反した規約の名前
  message: string; // 違反内容の詳細メッセージ
}