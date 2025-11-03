import Foundation

// MARK: - Core Data Models

/// 規約違反情報を格納するモデル
struct Violation: Identifiable, Codable {
    let id = UUID()
    let line: Int
    let description: String
    let rule: String
    let ruleType: RuleType
    
    enum RuleType: String, Codable, CaseIterable {
        case primary = "主要規約"
        case secondary = "二次規約"
        case assignment = "課題規約"
    }
}

/// チェック結果を格納するモデル
struct CheckResult: Codable {
    let isCorrect: Bool
    let violations: [Violation]
    let correctedCode: String?
    let reportContent: String
    
    init(violations: [Violation], correctedCode: String? = nil) {
        self.isCorrect = violations.isEmpty
        self.violations = violations
        self.correctedCode = correctedCode
        self.reportContent = CheckResult.generateReport(violations: violations)
    }
    
    private static func generateReport(violations: [Violation]) -> String {
        if violations.isEmpty {
            return "correct"
        }
        
        var report = "コーディング規約違反レポート\n"
        report += String(repeating: "=", count: 30) + "\n\n"
        
        for (index, violation) in violations.enumerated() {
            report += "\(index + 1). 行 \(violation.line): \(violation.description)\n"
            report += "   規約種別: \(violation.ruleType.rawValue)\n"
            report += "   規約内容: \(violation.rule)\n\n"
        }
        
        return report
    }
}

/// ファイル情報を格納するモデル
struct FileInfo: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let content: String
    let type: FileType
    
    enum FileType: String, CaseIterable {
        case primaryRule = "主要規約ファイル"
        case secondaryRule = "二次規約ファイル"
        case cSource = "Cソースファイル"
        case report = "レポートファイル"
        case corrected = "修正版ファイル"
    }
    
    init(url: URL, type: FileType) throws {
        self.url = url
        self.name = url.lastPathComponent
        self.type = type
        
        // ファイル内容を読み込み
        guard url.startAccessingSecurityScopedResource() else {
            throw FileError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            self.content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw FileError.readFailed(error.localizedDescription)
        }
        
        // ファイル形式の検証
        try self.validateFile()
    }
    
    private func validateFile() throws {
        // 空ファイルチェック
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw FileError.emptyFile
        }
        
        // ファイル拡張子チェック
        switch type {
        case .primaryRule, .secondaryRule, .report:
            guard url.pathExtension.lowercased() == "txt" else {
                throw FileError.invalidExtension("txtファイルを選択してください")
            }
        case .cSource, .corrected:
            guard url.pathExtension.lowercased() == "c" else {
                throw FileError.invalidExtension("cファイルを選択してください")
            }
        }
        
        // ファイルサイズチェック（10MB制限）
        if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
           fileSize > 10_000_000 {
            throw FileError.fileTooLarge
        }
    }
}

/// ファイル関連エラー
enum FileError: LocalizedError {
    case accessDenied
    case readFailed(String)
    case emptyFile
    case invalidExtension(String)
    case fileTooLarge
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "ファイルへのアクセスが拒否されました"
        case .readFailed(let message):
            return "ファイルの読み込みに失敗しました: \(message)"
        case .emptyFile:
            return "空のファイルは使用できません"
        case .invalidExtension(let message):
            return message
        case .fileTooLarge:
            return "ファイルサイズが大きすぎます（10MB以下にしてください）"
        }
    }
}

/// 課題テンプレート管理
struct AssignmentTemplate {
    static let templates: [String: String] = [
        "課題1": """
#include <stdio.h>

int main() {
    // 課題1: Hello World を出力するプログラム
    // TODO: printf関数を使用してHello Worldを出力してください
    
    return 0;
}
""",
        "課題2": """
#include <stdio.h>

int main() {
    // 課題2: 変数を使った計算プログラム
    // TODO: int型の変数を宣言し、計算を行ってください
    
    return 0;
}
""",
        "課題3": """
#include <stdio.h>

int main() {
    // 課題3: 条件分岐を使ったプログラム
    // TODO: if文を使用した条件分岐を実装してください
    
    return 0;
}
""",
        "課題4": """
#include <stdio.h>

int main() {
    // 課題4: ループを使ったプログラム
    // TODO: for文またはwhile文を使用したループを実装してください
    
    return 0;
}
"""
    ]
    
    static func getTemplate(for assignment: String) -> String? {
        return templates[assignment]
    }
    
    static func getAllAssignments() -> [String] {
        return templates.keys.sorted()
    }
}