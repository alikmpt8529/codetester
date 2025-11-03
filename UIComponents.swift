import SwiftUI
import UniformTypeIdentifiers

// MARK: - File Upload Components

/// ファイルアップロード用のカードコンポーネント
struct FileUploadCard: View {
    let title: String
    let subtitle: String
    let fileInfo: FileInfo?
    let onUpload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: fileInfo == nil ? "doc.badge.plus" : "doc.checkmark.fill")
                    .foregroundColor(fileInfo == nil ? .blue : .green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("選択", action: onUpload)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            
            if let file = fileInfo {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("✓ \(file.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(fileInfo == nil ? Color.gray.opacity(0.3) : Color.green.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

/// ファイルピッカービュー
struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onPick(url)
        }
    }
}

// MARK: - Result Display Components

/// チェック結果表示カード
struct CheckResultCard: View {
    let checkResult: CheckResult
    let onExportReport: () -> Void
    let onDownloadCorrected: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: checkResult.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(checkResult.isCorrect ? .green : .red)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(checkResult.isCorrect ? "規約準拠" : "規約違反")
                        .font(.headline)
                        .foregroundColor(checkResult.isCorrect ? .green : .red)
                    
                    Text(checkResult.isCorrect ? "すべての規約に準拠しています" : "\(checkResult.violations.count)件の違反が見つかりました")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 違反詳細（違反がある場合）
            if !checkResult.isCorrect {
                ViolationListView(violations: checkResult.violations)
            }
            
            // アクションボタン
            HStack {
                Button("レポート出力") {
                    onExportReport()
                }
                .buttonStyle(.bordered)
                
                if let onDownloadCorrected = onDownloadCorrected {
                    Button("修正版ダウンロード") {
                        onDownloadCorrected()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(checkResult.isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(checkResult.isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// 違反リスト表示ビュー
struct ViolationListView: View {
    let violations: [Violation]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("違反詳細 (\(violations.count)件)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(violations.prefix(10)) { violation in
                        ViolationRowView(violation: violation)
                    }
                    
                    if violations.count > 10 {
                        Text("... および \(violations.count - 10) 件の違反")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.leading)
            }
        }
    }
}

/// 個別の違反表示行
struct ViolationRowView: View {
    let violation: Violation
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(violation.line)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(minWidth: 24, minHeight: 20)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(violation.ruleType == .assignment ? Color.orange : Color.red)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(violation.description)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text("[\(violation.ruleType.rawValue)] \(violation.rule)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Progress and Status Components

/// 処理中のプログレス表示
struct ProcessingProgressView: View {
    let progress: Double
    let isProcessing: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("コーディング規約をチェック中...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if progress > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

/// エラーメッセージ表示
struct ErrorMessageView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("閉じる", action: onDismiss)
                .font(.caption)
                .buttonStyle(.borderless)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Assignment Generation Components

/// 課題生成セクション
struct AssignmentGenerationView: View {
    let canGenerate: Bool
    let onGenerateSingle: (String) -> Void
    let onGenerateAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("課題テンプレート生成")
                        .font(.headline)
                    
                    Text("二次規約ファイルに基づいて課題テンプレートを生成します")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if canGenerate {
                VStack(spacing: 8) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(AssignmentTemplate.getAllAssignments(), id: \.self) { assignment in
                            Button(assignment) {
                                onGenerateSingle(assignment)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    
                    Button("全課題一括生成") {
                        onGenerateAll()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("二次規約ファイルが必要です")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Control Components

/// メインアクションボタン
struct MainActionButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let isProcessing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: systemImage)
                }
                
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isEnabled || isProcessing)
        .controlSize(.large)
    }
}

/// クリアボタン
struct ClearAllButton: View {
    let action: () -> Void
    
    var body: some View {
        Button("全てクリア") {
            action()
        }
        .buttonStyle(.bordered)
        .foregroundColor(.red)
    }
}

// MARK: - Export Components

/// ファイルエクスポート用シート
struct FileExportSheet: View {
    @ObservedObject var exportManager: ExportManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let exportFile = exportManager.selectedExportFile {
                    SingleFileExportView(exportFile: exportFile)
                } else if !exportManager.exportFiles.isEmpty {
                    MultipleFilesExportView(exportFiles: exportManager.exportFiles)
                } else {
                    Text("エクスポートするファイルがありません")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("ファイルエクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        exportManager.hideExportDialog()
                    }
                }
            }
        }
    }
}

/// 単一ファイルエクスポートビュー
struct SingleFileExportView: View {
    let exportFile: ExportFileInfo
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text(exportFile.fileName)
                .font(.headline)
            
            Text("ファイルサイズ: \(ByteCountFormatter.string(fromByteCount: Int64(exportFile.data.count), countStyle: .file))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ShareLink(
                item: exportFile.data,
                preview: SharePreview(exportFile.fileName)
            ) {
                Label("ファイルをエクスポート", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

/// 複数ファイルエクスポートビュー
struct MultipleFilesExportView: View {
    let exportFiles: [ExportFileInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(exportFiles.count)個のファイルをエクスポート")
                .font(.headline)
            
            ForEach(exportFiles) { file in
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    
                    Text(file.fileName)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    ShareLink(
                        item: file.data,
                        preview: SharePreview(file.fileName)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 4)
            }
        }
    }
}