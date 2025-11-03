import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // MARK: - State Management
    @StateObject private var fileManager = AppFileManager()
    @StateObject private var exportManager = ExportManager()
    @StateObject private var filePickerManager = FilePickerManager()
    @StateObject private var appSettings = AppSettings()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダーセクション
                    headerSection
                    
                    // ファイルアップロードセクション
                    fileUploadSection
                    
                    // エラーメッセージ表示
                    errorSection
                    
                    // 処理中プログレス表示
                    progressSection
                    
                    // メインアクション
                    actionSection
                    
                    // チェック結果表示
                    resultSection
                    
                    // 課題生成セクション
                    assignmentSection
                }
                .padding()
            }
            .navigationTitle("コーディング規約チェッカー")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
        }
        .sheet(isPresented: $filePickerManager.isShowingPicker) {
            filePickerSheet
        }
        .sheet(isPresented: $exportManager.isShowingExportDialog) {
            FileExportSheet(exportManager: exportManager)
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("C言語 コーディング規約チェッカー")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("規約ファイルとCソースファイルをアップロードしてチェックを実行してください")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    private var fileUploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ファイルアップロード")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // 主要規約ファイル
                FileUploadCard(
                    title: "主要規約ファイル",
                    subtitle: "必須 - メインのコーディング規約を定義したtxtファイル",
                    fileInfo: fileManager.primaryRuleFile
                ) {
                    filePickerManager.showPicker(for: .primaryRule)
                }
                
                // 二次規約ファイル
                FileUploadCard(
                    title: "二次規約ファイル",
                    subtitle: "任意 - 課題用規約を含む追加のtxtファイル",
                    fileInfo: fileManager.secondaryRuleFile
                ) {
                    filePickerManager.showPicker(for: .secondaryRule)
                }
                
                // Cソースファイル
                FileUploadCard(
                    title: "Cソースファイル",
                    subtitle: "必須 - チェック対象のC言語ファイル",
                    fileInfo: fileManager.cSourceFile
                ) {
                    filePickerManager.showPicker(for: .cSource)
                }
            }
        }
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = fileManager.errorMessage {
            ErrorMessageView(message: errorMessage) {
                fileManager.errorMessage = nil
            }
        }
    }
    
    @ViewBuilder
    private var progressSection: some View {
        if fileManager.isProcessing {
            ProcessingProgressView(
                progress: fileManager.processingProgress,
                isProcessing: fileManager.isProcessing
            )
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            // メインチェックボタン
            MainActionButton(
                title: "チェック実行",
                systemImage: "play.circle.fill",
                isEnabled: fileManager.canPerformCheck,
                isProcessing: fileManager.isProcessing
            ) {
                performCheck()
            }
            
            // クリアボタン
            HStack {
                Spacer()
                
                ClearAllButton {
                    clearAllFiles()
                }
            }
        }
    }
    
    @ViewBuilder
    private var resultSection: some View {
        if let checkResult = fileManager.currentCheckResult {
            VStack(alignment: .leading, spacing: 16) {
                Text("チェック結果")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                CheckResultCard(
                    checkResult: checkResult,
                    onExportReport: {
                        exportManager.prepareReportExport(from: checkResult)
                    },
                    onDownloadCorrected: checkResult.correctedCode != nil ? {
                        exportCorrectedCode(checkResult)
                    } : nil
                )
            }
        }
    }
    
    @ViewBuilder
    private var assignmentSection: some View {
        if fileManager.secondaryRuleFile != nil {
            VStack(alignment: .leading, spacing: 16) {
                Text("課題テンプレート")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                AssignmentGenerationView(
                    canGenerate: fileManager.canGenerateAssignments,
                    onGenerateSingle: { assignment in
                        exportManager.prepareAssignmentExport(for: assignment)
                    },
                    onGenerateAll: {
                        exportManager.prepareMultipleAssignmentExport()
                    }
                )
            }
        }
    }
    
    // MARK: - Toolbar Content
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button("設定") {
                    // 設定画面を開く（将来の拡張用）
                }
                
                Button("ヘルプ") {
                    // ヘルプ画面を開く（将来の拡張用）
                }
                
                Divider()
                
                Button("デバッグモード: \(appSettings.enableDebugMode ? "ON" : "OFF")") {
                    appSettings.enableDebugMode.toggle()
                    appSettings.saveSettings()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    // MARK: - Sheet Content
    
    @ViewBuilder
    private var filePickerSheet: some View {
        if let pickerType = filePickerManager.activePickerType {
            DocumentPicker(
                contentTypes: pickerType.allowedContentTypes
            ) { url in
                handleFilePick(url: url, type: pickerType)
                filePickerManager.hidePicker()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        // アプリ初期化時の処理
        if appSettings.enableDebugMode {
            print("🛠 デバッグモードが有効です")
        }
    }
    
    private func handleFilePick(url: URL, type: FilePickerManager.PickerType) {
        fileManager.loadFile(from: url, type: type.fileType)
    }
    
    private func performCheck() {
        // チェック実行前の準備
        guard fileManager.canPerformCheck else {
            fileManager.errorMessage = "必要なファイルがアップロードされていません"
            return
        }
        
        // チェック実行
        fileManager.performCheck()
    }
    
    private func clearAllFiles() {
        // 確認アラートを表示（将来の拡張用）
        fileManager.clearAllFiles()
    }
    
    private func exportCorrectedCode(_ checkResult: CheckResult) {
        guard let correctedCode = checkResult.correctedCode,
              let originalFileName = fileManager.cSourceFile?.name else {
            return
        }
        
        exportManager.prepareCorrectedCodeExport(
            from: correctedCode,
            originalFileName: originalFileName
        )
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("メインビュー")
        
        // 異なる状態でのプレビュー
        ContentView()
            .previewDisplayName("ダークモード")
            .preferredColorScheme(.dark)
    }
}

// MARK: - Helper Extensions

extension ContentView {
    
    /// デバッグ用のサンプルデータを作成
    private func createSampleData() -> CheckResult {
        let sampleViolations = [
            Violation(
                line: 5,
                description: "セミコロンが不足しています",
                rule: "C言語では文の終わりにセミコロンが必要です",
                ruleType: .primary
            ),
            Violation(
                line: 8,
                description: "インデントが正しくありません",
                rule: "関数内のコードは4スペースでインデントしてください",
                ruleType: .primary
            ),
            Violation(
                line: 1,
                description: "課題1: Hello Worldの出力が必要です",
                rule: "課題1の要件を満たしてください",
                ruleType: .assignment
            )
        ]
        
        return CheckResult(violations: sampleViolations)
    }
}

// MARK: - Accessibility

extension ContentView {
    
    /// アクセシビリティ対応のための拡張
    private func setupAccessibility() {
        // VoiceOver対応などのアクセシビリティ設定
        // 将来の拡張用
    }
}