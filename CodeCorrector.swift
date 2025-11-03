import Foundation

/// コード修正機能 - 違反箇所にコメントを追加して修正版を生成
class CodeCorrector {
    
    // MARK: - Public Methods
    
    /// 違反箇所にコメントを追加した修正版コードを生成
    /// - Parameters:
    ///   - code: 元のソースコード
    ///   - violations: 違反情報のリスト
    /// - Returns: 修正版コード（違反箇所にコメント追加済み）
    static func addViolationComments(code: String, violations: [Violation]) -> String {
        if violations.isEmpty {
            return code
        }
        
        var lines = code.components(separatedBy: .newlines)
        let violationsByLine = groupViolationsByLine(violations)
        
        // 行番号の降順で処理して、行番号のずれを防ぐ
        let sortedLineNumbers = violationsByLine.keys.sorted(by: >)
        
        for lineNumber in sortedLineNumbers {
            guard let lineViolations = violationsByLine[lineNumber] else { continue }
            let arrayIndex = lineNumber - 1
            
            // 行が存在する場合のみ処理
            guard arrayIndex >= 0 && arrayIndex < lines.count else { continue }
            
            // 違反コメントを生成して挿入
            let violationComments = generateViolationComments(lineViolations)
            
            // 元の行の前にコメントを挿入
            for (index, comment) in violationComments.enumerated() {
                lines.insert(comment, at: arrayIndex + index)
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// 自動修正を試行（基本的な修正のみ）
    /// - Parameters:
    ///   - code: 元のソースコード
    ///   - violations: 違反情報のリスト
    /// - Returns: 自動修正版コード
    static func attemptAutoCorrection(code: String, violations: [Violation]) -> String {
        var correctedCode = code
        var lines = correctedCode.components(separatedBy: .newlines)
        
        // セミコロン不足の自動修正
        for violation in violations {
            if violation.description.contains("セミコロンが不足") {
                let lineIndex = violation.line - 1
                if lineIndex >= 0 && lineIndex < lines.count {
                    let line = lines[lineIndex]
                    if !line.hasSuffix(";") && !line.contains("{") && !line.contains("}") {
                        lines[lineIndex] = line + ";"
                    }
                }
            }
        }
        
        // 基本的なインデント修正
        for violation in violations {
            if violation.description.contains("インデント") {
                let lineIndex = violation.line - 1
                if lineIndex >= 0 && lineIndex < lines.count {
                    let line = lines[lineIndex]
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    
                    // 関数内のコードと思われる場合、4スペースのインデントを追加
                    if !trimmedLine.hasPrefix("#") && 
                       !trimmedLine.contains("int main") &&
                       !trimmedLine.contains("}") {
                        lines[lineIndex] = "    " + trimmedLine
                    }
                }
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Private Methods
    
    /// 違反情報を行番号でグループ化
    private static func groupViolationsByLine(_ violations: [Violation]) -> [Int: [Violation]] {
        return Dictionary(grouping: violations) { $0.line }
    }
    
    /// 違反情報からコメントを生成
    private static func generateViolationComments(_ violations: [Violation]) -> [String] {
        var comments: [String] = []
        
        // 違反の重要度で並び替え（重要なものから）
        let sortedViolations = violations.sorted { violation1, violation2 in
            return getViolationPriority(violation1) > getViolationPriority(violation2)
        }
        
        for violation in sortedViolations {
            let comment = generateSingleComment(violation)
            comments.append(comment)
        }
        
        // 違反が複数ある場合は区切り線を追加
        if violations.count > 1 {
            comments.insert("// " + String(repeating: "-", count: 40), at: 0)
            comments.append("// " + String(repeating: "-", count: 40))
        }
        
        return comments
    }
    
    /// 単一の違反に対するコメントを生成
    private static func generateSingleComment(_ violation: Violation) -> String {
        let prefix = "// [違反]"
        let ruleTypeIndicator = getRuleTypeIndicator(violation.ruleType)
        let description = violation.description
        
        return "\(prefix) \(ruleTypeIndicator) \(description)"
    }
    
    /// 規約種別のインジケーターを取得
    private static func getRuleTypeIndicator(_ ruleType: Violation.RuleType) -> String {
        switch ruleType {
        case .primary:
            return "[主要規約]"
        case .secondary:
            return "[二次規約]"
        case .assignment:
            return "[課題要件]"
        }
    }
    
    /// 違反の優先度を取得（数値が大きいほど重要）
    private static func getViolationPriority(_ violation: Violation) -> Int {
        // 規約種別による基本優先度
        var priority = 0
        switch violation.ruleType {
        case .assignment:
            priority += 100  // 課題要件が最重要
        case .primary:
            priority += 50   // 主要規約は重要
        case .secondary:
            priority += 25   // 二次規約は中程度
        }
        
        // 違反内容による優先度調整
        let description = violation.description.lowercased()
        if description.contains("セミコロン") {
            priority += 20  // 構文エラーは重要
        } else if description.contains("インデント") {
            priority += 10  // 見た目の問題は中程度
        } else if description.contains("コメント") {
            priority += 5   // コメントは軽微
        }
        
        return priority
    }
}

/// ファイル出力管理クラス
class FileOutputManager {
    
    // MARK: - Public Methods
    
    /// レポートファイルを生成してエクスポート用データを作成
    /// - Parameter checkResult: チェック結果
    /// - Returns: エクスポート用のファイルデータ
    static func createReportFileData(_ checkResult: CheckResult) -> Data? {
        return checkResult.reportContent.data(using: .utf8)
    }
    
    /// 修正版ファイルを生成してエクスポート用データを作成
    /// - Parameter correctedCode: 修正版コード
    /// - Returns: エクスポート用のファイルデータ
    static func createCorrectedFileData(_ correctedCode: String) -> Data? {
        return correctedCode.data(using: .utf8)
    }
    
    /// 課題テンプレートファイルを生成
    /// - Parameter assignment: 課題名
    /// - Returns: 課題テンプレートのファイルデータ
    static func createAssignmentFileData(for assignment: String) -> Data? {
        guard let template = AssignmentTemplate.getTemplate(for: assignment) else {
            return nil
        }
        return template.data(using: .utf8)
    }
    
    /// ファイル名を生成（タイムスタンプ付き）
    /// - Parameters:
    ///   - baseName: ベースとなるファイル名
    ///   - extension: ファイル拡張子
    /// - Returns: タイムスタンプ付きのファイル名
    static func generateFileName(baseName: String, extension: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        
        return "\(baseName)_\(timestamp).\(`extension`)"
    }
    
    /// エクスポート用のファイル情報を作成
    /// - Parameters:
    ///   - data: ファイルデータ
    ///   - fileName: ファイル名
    ///   - fileType: ファイルタイプ
    /// - Returns: エクスポート用ファイル情報
    static func createExportFileInfo(
        data: Data,
        fileName: String,
        fileType: FileInfo.FileType
    ) -> ExportFileInfo {
        return ExportFileInfo(
            data: data,
            fileName: fileName,
            fileType: fileType
        )
    }
}

/// エクスポート用ファイル情報
struct ExportFileInfo: Identifiable {
    let id = UUID()
    let data: Data
    let fileName: String
    let fileType: FileInfo.FileType
    let createdAt = Date()
    
    var mimeType: String {
        switch fileType {
        case .report, .primaryRule, .secondaryRule:
            return "text/plain"
        case .cSource, .corrected:
            return "text/x-c"
        }
    }
}