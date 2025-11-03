import Foundation

/// コーディング規約チェッカー - 仕様に基づいたチェック機能を提供
class CodingRuleChecker {
    
    // MARK: - Public Methods
    
    /// メインのチェック機能：仕様通りの順序でチェックを実行
    /// - Parameters:
    ///   - codeFile: Cソースファイル情報
    ///   - primaryRuleFile: 主要規約ファイル情報
    ///   - secondaryRuleFile: 二次規約ファイル情報（任意）
    /// - Returns: チェック結果
    static func checkCode(
        codeFile: FileInfo,
        primaryRuleFile: FileInfo,
        secondaryRuleFile: FileInfo? = nil
    ) -> CheckResult {
        var allViolations: [Violation] = []
        
        // チェック順序は仕様通り：二次規約 → 主要規約
        
        // 1. 二次規約のチェック（存在する場合）
        if let secondaryFile = secondaryRuleFile {
            let secondaryViolations = performRuleCheck(
                code: codeFile.content,
                rules: secondaryFile.content,
                ruleType: .secondary
            )
            allViolations.append(contentsOf: secondaryViolations)
        }
        
        // 2. 主要規約のチェック
        let primaryViolations = performRuleCheck(
            code: codeFile.content,
            rules: primaryRuleFile.content,
            ruleType: .primary
        )
        allViolations.append(contentsOf: primaryViolations)
        
        // 修正版コードの生成（違反がある場合）
        let correctedCode = allViolations.isEmpty ? nil : 
            CodeCorrector.addViolationComments(
                code: codeFile.content,
                violations: allViolations
            )
        
        return CheckResult(violations: allViolations, correctedCode: correctedCode)
    }
    
    // MARK: - Private Methods
    
    /// 規約に基づく具体的なチェック処理
    private static func performRuleCheck(
        code: String,
        rules: String,
        ruleType: Violation.RuleType
    ) -> [Violation] {
        var violations: [Violation] = []
        let codeLines = code.components(separatedBy: .newlines)
        let ruleLines = rules.components(separatedBy: .newlines)
        
        // 基本的なC言語規約チェック
        violations.append(contentsOf: checkBasicSyntax(
            codeLines: codeLines,
            ruleType: ruleType
        ))
        
        // 規約ファイルの内容に基づく特定チェック
        violations.append(contentsOf: checkSpecificRules(
            code: code,
            codeLines: codeLines,
            ruleLines: ruleLines,
            ruleType: ruleType
        ))
        
        return violations
    }
    
    /// 基本的なC言語構文のチェック
    private static func checkBasicSyntax(
        codeLines: [String],
        ruleType: Violation.RuleType
    ) -> [Violation] {
        var violations: [Violation] = []
        
        for (lineIndex, line) in codeLines.enumerated() {
            let lineNumber = lineIndex + 1
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty { continue }
            
            // セミコロンチェック
            if let semicolonViolation = checkSemicolon(
                line: trimmedLine,
                lineNumber: lineNumber,
                ruleType: ruleType
            ) {
                violations.append(semicolonViolation)
            }
            
            // インデントチェック
            if let indentViolation = checkIndentation(
                originalLine: line,
                trimmedLine: trimmedLine,
                lineNumber: lineNumber,
                ruleType: ruleType
            ) {
                violations.append(indentViolation)
            }
            
            // 基本構文チェック
            violations.append(contentsOf: checkBasicGrammar(
                line: trimmedLine,
                lineNumber: lineNumber,
                ruleType: ruleType
            ))
        }
        
        return violations
    }
    
    /// セミコロンの有無をチェック
    private static func checkSemicolon(
        line: String,
        lineNumber: Int,
        ruleType: Violation.RuleType
    ) -> Violation? {
        let requiresSemicolon = [
            "printf", "scanf", "return", "int ", "float ", "double ", "char "
        ].contains { line.contains($0) }
        
        let isSpecialCase = line.contains("{") || line.contains("}") || 
                           line.hasPrefix("#") || line.contains("//") ||
                           line.contains("int main")
        
        if requiresSemicolon && !isSpecialCase && !line.hasSuffix(";") {
            return Violation(
                line: lineNumber,
                description: "セミコロンが不足しています",
                rule: "C言語では文の終わりにセミコロンが必要です",
                ruleType: ruleType
            )
        }
        
        return nil
    }
    
    /// インデントをチェック
    private static func checkIndentation(
        originalLine: String,
        trimmedLine: String,
        lineNumber: Int,
        ruleType: Violation.RuleType
    ) -> Violation? {
        let shouldBeIndented = !trimmedLine.hasPrefix("#") && 
                              !trimmedLine.contains("int main") &&
                              !trimmedLine.contains("}") &&
                              !originalLine.trimmingCharacters(in: .whitespaces).isEmpty
        
        let isInsideFunction = !trimmedLine.contains("int main") &&
                              !trimmedLine.hasPrefix("#include") &&
                              !trimmedLine.contains("{") && 
                              !trimmedLine.contains("}")
        
        if shouldBeIndented && isInsideFunction && !originalLine.hasPrefix("    ") {
            return Violation(
                line: lineNumber,
                description: "インデントが正しくありません（4スペース必要）",
                rule: "関数内のコードは4スペースでインデントしてください",
                ruleType: ruleType
            )
        }
        
        return nil
    }
    
    /// 基本的な文法チェック
    private static func checkBasicGrammar(
        line: String,
        lineNumber: Int,
        ruleType: Violation.RuleType
    ) -> [Violation] {
        var violations: [Violation] = []
        
        // 括弧の対応チェック
        let openBraces = line.filter { $0 == "{" }.count
        let closeBraces = line.filter { $0 == "}" }.count
        let openParens = line.filter { $0 == "(" }.count
        let closeParens = line.filter { $0 == ")" }.count
        
        if openBraces != closeBraces && (openBraces > 0 || closeBraces > 0) {
            violations.append(Violation(
                line: lineNumber,
                description: "波括弧の対応が正しくありません",
                rule: "波括弧は正しく対応させてください",
                ruleType: ruleType
            ))
        }
        
        if openParens != closeParens && (openParens > 0 || closeParens > 0) {
            violations.append(Violation(
                line: lineNumber,
                description: "丸括弧の対応が正しくありません",
                rule: "丸括弧は正しく対応させてください",
                ruleType: ruleType
            ))
        }
        
        return violations
    }
    
    /// 規約ファイルに基づく特定のルールチェック
    private static func checkSpecificRules(
        code: String,
        codeLines: [String],
        ruleLines: [String],
        ruleType: Violation.RuleType
    ) -> [Violation] {
        var violations: [Violation] = []
        
        for rule in ruleLines {
            let trimmedRule = rule.trimmingCharacters(in: .whitespaces)
            if trimmedRule.isEmpty { continue }
            
            // 課題関連のチェック
            if let assignmentViolation = checkAssignmentRequirement(
                code: code,
                rule: trimmedRule,
                ruleType: ruleType
            ) {
                violations.append(assignmentViolation)
            }
            
            // カスタム規約のチェック
            violations.append(contentsOf: checkCustomRules(
                code: code,
                codeLines: codeLines,
                rule: trimmedRule,
                ruleType: ruleType
            ))
        }
        
        return violations
    }
    
    /// 課題要件のチェック
    private static func checkAssignmentRequirement(
        code: String,
        rule: String,
        ruleType: Violation.RuleType
    ) -> Violation? {
        if rule.contains("課題1") || rule.contains("Hello") {
            if !code.contains("printf") || !code.contains("Hello") {
                return Violation(
                    line: 1,
                    description: "課題1: Hello Worldの出力が必要です",
                    rule: rule,
                    ruleType: .assignment
                )
            }
        }
        
        if rule.contains("課題2") || rule.contains("変数") {
            if !code.contains("int ") && !code.contains("float ") && !code.contains("double ") {
                return Violation(
                    line: 1,
                    description: "課題2: 変数の宣言が必要です",
                    rule: rule,
                    ruleType: .assignment
                )
            }
        }
        
        if rule.contains("課題3") || rule.contains("条件分岐") {
            if !code.contains("if") && !code.contains("switch") {
                return Violation(
                    line: 1,
                    description: "課題3: 条件分岐(if文またはswitch文)が必要です",
                    rule: rule,
                    ruleType: .assignment
                )
            }
        }
        
        if rule.contains("課題4") || rule.contains("ループ") {
            if !code.contains("for") && !code.contains("while") && !code.contains("do") {
                return Violation(
                    line: 1,
                    description: "課題4: ループ処理(for文、while文、またはdo-while文)が必要です",
                    rule: rule,
                    ruleType: .assignment
                )
            }
        }
        
        return nil
    }
    
    /// カスタム規約のチェック
    private static func checkCustomRules(
        code: String,
        codeLines: [String],
        rule: String,
        ruleType: Violation.RuleType
    ) -> [Violation] {
        var violations: [Violation] = []
        
        // コメント規約
        if rule.contains("コメント") {
            for (lineIndex, line) in codeLines.enumerated() {
                if line.contains("//") {
                    let commentPart = line.components(separatedBy: "//").dropFirst().joined(separator: "//")
                    if commentPart.trimmingCharacters(in: .whitespaces).isEmpty {
                        violations.append(Violation(
                            line: lineIndex + 1,
                            description: "空のコメントは避けてください",
                            rule: rule,
                            ruleType: ruleType
                        ))
                    }
                }
            }
        }
        
        // 関数命名規約
        if rule.contains("関数名") || rule.contains("命名") {
            for (lineIndex, line) in codeLines.enumerated() {
                if line.contains("(") && line.contains(")") && !line.contains("main") && !line.contains("printf") {
                    // 簡単な関数名チェック（実際の実装では正規表現を使用）
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if trimmedLine.contains("_") && rule.contains("キャメルケース") {
                        violations.append(Violation(
                            line: lineIndex + 1,
                            description: "関数名はキャメルケースで命名してください",
                            rule: rule,
                            ruleType: ruleType
                        ))
                    }
                }
            }
        }
        
        return violations
    }
}