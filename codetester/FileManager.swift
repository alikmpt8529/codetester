import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// アプリケーション全体のファイル管理を担当
class AppFileManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var primaryRuleFile: FileInfo?
    @Published var secondaryRuleFile: FileInfo?
    @Published var cSourceFile: FileInfo?
    @Published var currentCheckResult: CheckResult?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var processingProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let maxFileSize: Int = 10_000_000 // 10MB
    private let allowedExtensions = ["txt", "c"]
    
    // MARK: - Public Methods
    
    /// ファイルをロードして検証
    func loadFile(from url: URL, type: FileInfo.FileType) {
        clearError()
        
        do {
            let fileInfo = try FileInfo(url: url, type: type)
            
            switch type {
            case .primaryRule:
                primaryRuleFile = fileInfo
            case .secondaryRule:
                secondaryRuleFile = fileInfo
            case .cSource:
                cSourceFile = fileInfo
            default:
                break
            }
            
            print("✅ ファイルロード成功: \(fileInfo.name)")
            
        } catch {
            handleFileError(error)
        }
    }
    
    /// コーディング規約チェックを実行
    func performCheck() {
        guard let primaryRule = primaryRuleFile,
              let cSource = cSourceFile else {
            setError("主要規約ファイルとCソースファイルが必要です")
            return
        }
        
        clearError()
        isProcessing = true
        processingProgress = 0.0
        
        // バックグラウンドでチェック処理を実行
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 進行状況の更新
            DispatchQueue.main.async {
                self.processingProgress = 0.3
            }
            
            // チェック実行
            let result = CodingRuleChecker.checkCode(
                codeFile: cSource,
                primaryRuleFile: primaryRule,
                secondaryRuleFile: self.secondaryRuleFile
            )
            
            // 進行状況の更新
            DispatchQueue.main.async {
                self.processingProgress = 1.0
            }
            
            // 結果をメインスレッドで更新
            DispatchQueue.main.async {
                self.currentCheckResult = result
                self.isProcessing = false
                self.processingProgress = 0.0
                
                print("✅ チェック完了: \(result.violations.count)件の違反")
            }
        }
    }
    
    /// ファイルを全てクリア
    func clearAllFiles() {
        primaryRuleFile = nil
        secondaryRuleFile = nil
        cSourceFile = nil
        currentCheckResult = nil
        clearError()
        
        print("📝 全ファイルをクリアしました")
    }
    
    /// 課題テンプレート生成の可否を確認
    var canGenerateAssignments: Bool {
        return secondaryRuleFile != nil
    }
    
    /// 修正版ダウンロードの可否を確認
    var canDownloadCorrectedVersion: Bool {
        return currentCheckResult?.correctedCode != nil
    }
    
    /// チェック実行の可否を確認
    var canPerformCheck: Bool {
        return primaryRuleFile != nil && cSourceFile != nil && !isProcessing
    }
    
    // MARK: - Private Methods
    
    private func clearError() {
        errorMessage = nil
    }
    
    private func setError(_ message: String) {
        errorMessage = message
        print("❌ エラー: \(message)")
    }
    
    private func handleFileError(_ error: Error) {
        if let fileError = error as? FileError {
            setError(fileError.localizedDescription)
        } else {
            setError("ファイルの処理中にエラーが発生しました: \(error.localizedDescription)")
        }
    }
}

/// ファイルピッカーの管理
class FilePickerManager: ObservableObject {
    
    enum PickerType: Identifiable {
        case primaryRule
        case secondaryRule
        case cSource
        
        var id: String {
            switch self {
            case .primaryRule: return "primary"
            case .secondaryRule: return "secondary"
            case .cSource: return "source"
            }
        }
        
        var title: String {
            switch self {
            case .primaryRule: return "主要規約ファイル (.txt)"
            case .secondaryRule: return "二次規約ファイル (.txt)"
            case .cSource: return "Cソースファイル (.c)"
            }
        }
        
        var allowedContentTypes: [UTType] {
            switch self {
            case .primaryRule, .secondaryRule:
                return [.plainText, .text]
            case .cSource:
                return [.cSource, .cPlusPlusSource, .plainText]
            }
        }
        
        var fileType: FileInfo.FileType {
            switch self {
            case .primaryRule: return .primaryRule
            case .secondaryRule: return .secondaryRule
            case .cSource: return .cSource
            }
        }
    }
    
    @Published var activePickerType: PickerType?
    @Published var isShowingPicker = false
    
    func showPicker(for type: PickerType) {
        activePickerType = type
        isShowingPicker = true
    }
    
    func hidePicker() {
        isShowingPicker = false
        activePickerType = nil
    }
}

/// エクスポート機能の管理
class ExportManager: ObservableObject {
    
    @Published var isShowingExportDialog = false
    @Published var exportFiles: [ExportFileInfo] = []
    @Published var selectedExportFile: ExportFileInfo?
    
    // MARK: - Public Methods
    
    /// レポートファイルのエクスポート準備
    func prepareReportExport(from checkResult: CheckResult) {
        guard let data = FileOutputManager.createReportFileData(checkResult) else {
            print("❌ レポートファイルの作成に失敗しました")
            return
        }
        
        let fileName = FileOutputManager.generateFileName(
            baseName: "coding_rule_report",
            extension: "txt"
        )
        
        let exportFile = FileOutputManager.createExportFileInfo(
            data: data,
            fileName: fileName,
            fileType: .report
        )
        
        selectedExportFile = exportFile
        showExportDialog()
    }
    
    /// 修正版ファイルのエクスポート準備
    func prepareCorrectedCodeExport(from correctedCode: String, originalFileName: String) {
        guard let data = FileOutputManager.createCorrectedFileData(correctedCode) else {
            print("❌ 修正版ファイルの作成に失敗しました")
            return
        }
        
        let baseName = originalFileName.replacingOccurrences(of: ".c", with: "_corrected")
        let fileName = FileOutputManager.generateFileName(
            baseName: baseName,
            extension: "c"
        )
        
        let exportFile = FileOutputManager.createExportFileInfo(
            data: data,
            fileName: fileName,
            fileType: .corrected
        )
        
        selectedExportFile = exportFile
        showExportDialog()
    }
    
    /// 課題テンプレートのエクスポート準備
    func prepareAssignmentExport(for assignment: String) {
        guard let data = FileOutputManager.createAssignmentFileData(for: assignment) else {
            print("❌ 課題テンプレートの作成に失敗しました: \(assignment)")
            return
        }
        
        let fileName = FileOutputManager.generateFileName(
            baseName: assignment.lowercased(),
            extension: "c"
        )
        
        let exportFile = FileOutputManager.createExportFileInfo(
            data: data,
            fileName: fileName,
            fileType: .cSource
        )
        
        selectedExportFile = exportFile
        showExportDialog()
    }
    
    /// 複数ファイルのエクスポート準備
    func prepareMultipleAssignmentExport() {
        exportFiles.removeAll()
        
        for assignment in AssignmentTemplate.getAllAssignments() {
            guard let data = FileOutputManager.createAssignmentFileData(for: assignment) else {
                continue
            }
            
            let fileName = FileOutputManager.generateFileName(
                baseName: assignment.lowercased(),
                extension: "c"
            )
            
            let exportFile = FileOutputManager.createExportFileInfo(
                data: data,
                fileName: fileName,
                fileType: .cSource
            )
            
            exportFiles.append(exportFile)
        }
        
        showExportDialog()
    }
    
    // MARK: - Private Methods
    
    private func showExportDialog() {
        isShowingExportDialog = true
    }
    
    func hideExportDialog() {
        isShowingExportDialog = false
        selectedExportFile = nil
        exportFiles.removeAll()
    }
}

/// アプリケーション設定管理
class AppSettings: ObservableObject {
    
    @Published var autoSaveResults = true
    @Published var showDetailedProgress = false
    @Published var maxProcessingTime: TimeInterval = 30.0
    @Published var enableDebugMode = false
    
    // UserDefaults keys
    private enum Keys {
        static let autoSaveResults = "autoSaveResults"
        static let showDetailedProgress = "showDetailedProgress"
        static let maxProcessingTime = "maxProcessingTime"
        static let enableDebugMode = "enableDebugMode"
    }
    
    init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    func saveSettings() {
        UserDefaults.standard.set(autoSaveResults, forKey: Keys.autoSaveResults)
        UserDefaults.standard.set(showDetailedProgress, forKey: Keys.showDetailedProgress)
        UserDefaults.standard.set(maxProcessingTime, forKey: Keys.maxProcessingTime)
        UserDefaults.standard.set(enableDebugMode, forKey: Keys.enableDebugMode)
        
        print("⚙️ 設定を保存しました")
    }
    
    func resetSettings() {
        autoSaveResults = true
        showDetailedProgress = false
        maxProcessingTime = 30.0
        enableDebugMode = false
        saveSettings()
        
        print("⚙️ 設定をリセットしました")
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        autoSaveResults = UserDefaults.standard.bool(forKey: Keys.autoSaveResults)
        showDetailedProgress = UserDefaults.standard.bool(forKey: Keys.showDetailedProgress)
        maxProcessingTime = UserDefaults.standard.double(forKey: Keys.maxProcessingTime)
        enableDebugMode = UserDefaults.standard.bool(forKey: Keys.enableDebugMode)
        
        // デフォルト値の設定（初回起動時）
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            resetSettings()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
}