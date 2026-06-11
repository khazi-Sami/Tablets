import Combine
import Foundation
#if canImport(WhisperKit)
import WhisperKit
#endif

@MainActor
final class WhisperModelManager: ObservableObject {
    static let shared = WhisperModelManager()

    @Published private(set) var selectedModel: WhisperLocalModel
    @Published private(set) var downloadProgress: Double = 0
    @Published private(set) var isDownloading = false
    @Published private(set) var isLoading = false
    @Published private(set) var modelError: String?
    @Published private(set) var activeModelPath: String?
    @Published private(set) var downloadStatusText = "Ready to download"
    @Published private(set) var modelState: WhisperModelState = .notInstalled
    @Published private(set) var downloadedBytes: Int64 = 0
    @Published private(set) var totalBytes: Int64 = 0

    let availableModels = WhisperLocalModel.allCases

    private let fileManager = FileManager.default
    private var downloadTask: Task<Void, Never>?
    #if canImport(WhisperKit)
    private var loadedModelName: String?
    private var loadedWhisperKit: WhisperKit?
    #endif

    private init() {
        selectedModel = .tiny
        refreshState()
    }

    var selectedModelName: String {
        selectedModel.modelName
    }

    var selectedModelDisplayName: String {
        selectedModel.title
    }

    var installProgress: Double { downloadProgress }
    var isInstalling: Bool { isDownloading }
    var installError: String? { modelError }

    var installedModels: [WhisperLocalModel] {
        availableModels.filter { isInstalled($0) }
    }

    var isReady: Bool {
        if case .ready = modelState { return true }
        return false
    }

    var isModelLoaded: Bool {
        #if canImport(WhisperKit)
        loadedWhisperKit != nil && loadedModelName == selectedModel.modelName
        #else
        false
        #endif
    }

    var storageUsageText: String {
        let bytes = availableModels
            .compactMap { localModelFolder(for: $0) }
            .map { folderSize($0) }
            .reduce(0, +)
        guard bytes > 0 else { return "No model storage used yet" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    func selectBestModelForDevice(preferAccuracy: Bool = true) {
        let selectedName = WhisperModelSelector().selectedModelName(preferAccuracy: preferAccuracy)
        selectedModel = WhisperLocalModel(modelName: selectedName) ?? .tiny
        refreshState()
    }

    func selectModel(_ model: WhisperLocalModel) {
        guard !isDownloading, !isLoading else { return }
        selectedModel = model
        modelError = nil
        refreshState()
    }

    func isInstalled(_ model: WhisperLocalModel? = nil) -> Bool {
        localModelFolder(for: model ?? selectedModel) != nil &&
        UserDefaults.standard.bool(forKey: verifiedKey(for: model ?? selectedModel))
    }

    func localModelFolder(for modelName: String) -> URL? {
        guard let model = WhisperLocalModel(modelName: modelName) else { return nil }
        return localModelFolder(for: model)
    }

    func localModelFolder(for model: WhisperLocalModel) -> URL? {
        if let savedPath = UserDefaults.standard.string(forKey: installedPathKey(for: model)),
           isValidModelFolder(URL(fileURLWithPath: savedPath)) {
            return URL(fileURLWithPath: savedPath)
        }

        for candidate in localModelCandidates(for: model) where isValidModelFolder(candidate) {
            UserDefaults.standard.set(candidate.path, forKey: installedPathKey(for: model))
            return candidate
        }

        return bundledModelFolder(for: model)
    }

    func installSelectedModel() async {
        await install(selectedModel)
    }

    func install(_ model: WhisperLocalModel) async {
        selectedModel = model
        modelError = nil
        downloadProgress = 0
        downloadedBytes = 0
        totalBytes = selectedModel.estimatedBytes
        downloadStatusText = "Preparing download..."
        modelState = .preparing
        debugLog("Starting setup for \(selectedModel.title)")

        if let existing = localModelFolder(for: selectedModel),
           UserDefaults.standard.bool(forKey: verifiedKey(for: selectedModel)) {
            activeModelPath = existing.path
            downloadProgress = 1
            downloadedBytes = selectedModel.estimatedBytes
            downloadStatusText = "Ready to listen"
            modelState = .ready
            return
        }

        isDownloading = true
        defer { isDownloading = false }

        do {
            cleanupPartialInstall(for: selectedModel)
            guard let source = bundledModelFolder(for: selectedModel) else {
                try await downloadModel(selectedModel)
                try await verifyAndLoadInstalledModel(selectedModel)
                return
            }
            modelState = .installing
            downloadStatusText = "Installing model"
            let destination = installedModelFolder(for: selectedModel)
            try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            let files = try fileManager.subpathsOfDirectory(atPath: source.path)
            let total = max(files.count, 1)

            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
            for (index, relativePath) in files.enumerated() {
                let sourceURL = source.appending(path: relativePath)
                let destinationURL = destination.appending(path: relativePath)
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory)

                if isDirectory.boolValue {
                    try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
                } else {
                    try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                }

                downloadProgress = Double(index + 1) / Double(total)
                modelState = .downloading(progress: downloadProgress)
            }

            UserDefaults.standard.set(destination.path, forKey: installedPathKey(for: selectedModel))
            try await verifyAndLoadInstalledModel(selectedModel)
        } catch {
            modelError = friendlyMessage(for: error)
            downloadStatusText = "Download failed"
            modelState = .failed(message: modelError ?? "Model setup failed.")
            cleanupPartialInstall(for: selectedModel)
            debugLog("Setup failed: \(modelError ?? error.localizedDescription)")
        }
    }

    func startInstallSelectedModel() {
        downloadTask?.cancel()
        downloadTask = Task { [weak self] in
            guard let self else { return }
            await self.installSelectedModel()
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        modelError = "Model setup was cancelled."
        downloadStatusText = "Download cancelled"
        modelState = .failed(message: "Model setup was cancelled.")
    }

    #if canImport(WhisperKit)
    func loadedModel() async throws -> WhisperKit {
        if let loadedWhisperKit, loadedModelName == selectedModel.modelName {
            modelState = .ready
            return loadedWhisperKit
        }

        guard let folder = localModelFolder(for: selectedModel) else {
            throw WhisperModelManagerError.modelMissing
        }

        isLoading = true
        modelState = .loading
        defer { isLoading = false }

        do {
            let whisperKit = try await WhisperKit(modelFolder: folder.path, verbose: false, load: true, download: false)
            loadedWhisperKit = whisperKit
            loadedModelName = selectedModel.modelName
            activeModelPath = folder.path
            UserDefaults.standard.set(true, forKey: verifiedKey(for: selectedModel))
            modelState = .ready
            return whisperKit
        } catch {
            invalidate(model: selectedModel)
            modelError = "The offline voice model could not be loaded. Please retry the download."
            modelState = .failed(message: modelError ?? "Model loading failed.")
            throw error
        }
    }
    #endif

    private func downloadModel(_ model: WhisperLocalModel) async throws {
        #if canImport(WhisperKit)
        modelState = .downloading(progress: 0)
        downloadStatusText = "Downloading model"
        let tempRoot = tempDownloadFolder(for: model)
        let finalFolder = installedModelFolder(for: model)
        try? fileManager.removeItem(at: tempRoot)
        try? fileManager.removeItem(at: finalFolder)
        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        debugLog("Temp model folder: \(tempRoot.path)")
        debugLog("Final model folder: \(finalFolder.path)")

        let modelFolder = try await WhisperKit.download(
            variant: model.downloadVariant,
            downloadBase: tempRoot,
            useBackgroundSession: false,
            progressCallback: { progress in
                Task { @MainActor in
                    let diskBytes = Int64(self.folderSize(tempRoot))
                    let completed = max(diskBytes, 0)
                    let progressTotal = progress.totalUnitCount > 1_024 ? progress.totalUnitCount : model.estimatedBytes
                    let total = max(progressTotal, model.estimatedBytes)
                    self.downloadedBytes = completed
                    self.totalBytes = total
                    if completed > 1_024, total > 0, completed <= total {
                        self.downloadProgress = min(Double(completed) / Double(total), 0.99)
                    } else {
                        self.downloadProgress = 0
                    }
                    self.downloadStatusText = "Downloading model"
                    self.modelState = .downloading(progress: self.downloadProgress)
                    self.debugLog("Downloaded bytes: \(completed), expected total: \(total), progress: \(self.downloadProgress)")
                }
            }
        )
        modelState = .verifying
        downloadStatusText = "Verifying model"
        debugLog("Downloaded model folder returned by WhisperKit: \(modelFolder.path)")
        try verifyModelFolder(modelFolder)

        let destination = installedModelFolder(for: model)
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.moveItem(at: modelFolder, to: destination)
        try? fileManager.removeItem(at: tempRoot)
        modelState = .installing
        downloadStatusText = "Installing model"
        UserDefaults.standard.set(destination.path, forKey: installedPathKey(for: model))
        activeModelPath = destination.path
        downloadProgress = 1
        downloadedBytes = totalBytes > 0 ? totalBytes : model.estimatedBytes
        #else
        modelError = "The voice model package is not available in this build."
        #endif
    }

    #if canImport(WhisperKit)
    private func verifyAndLoadInstalledModel(_ model: WhisperLocalModel) async throws {
        modelState = .verifying
        downloadStatusText = "Verifying model"
        guard let folder = localModelFolder(for: model) else {
            throw WhisperModelManagerError.missingModelFiles
        }
        try verifyModelFolder(folder)

        modelState = .loading
        downloadStatusText = "Loading model"
        debugLog("Initializing WhisperKit from: \(folder.path)")
        let whisperKit = try await WhisperKit(modelFolder: folder.path, verbose: false, load: true, download: false)
        debugLog("WhisperKit initialization succeeded")
        loadedWhisperKit = whisperKit
        loadedModelName = model.modelName
        activeModelPath = folder.path
        UserDefaults.standard.set(true, forKey: verifiedKey(for: model))
        downloadProgress = 1
        downloadedBytes = totalBytes > 0 ? totalBytes : model.estimatedBytes
        downloadStatusText = "Ready to listen"
        modelState = .ready
    }
    #endif

    private func invalidate(model: WhisperLocalModel) {
        loadedWhisperKit = nil
        loadedModelName = nil
        UserDefaults.standard.removeObject(forKey: installedPathKey(for: model))
        UserDefaults.standard.set(false, forKey: verifiedKey(for: model))
    }

    private func bundledModelFolder(for model: WhisperLocalModel) -> URL? {
        [
            Bundle.main.url(forResource: model.resourceName, withExtension: nil, subdirectory: "WhisperModels"),
            Bundle.main.url(forResource: model.downloadedFolderHint, withExtension: nil, subdirectory: "WhisperModels"),
            Bundle.main.url(forResource: model.resourceName, withExtension: nil),
            Bundle.main.url(forResource: model.downloadedFolderHint, withExtension: nil)
        ]
        .compactMap { $0 }
        .first { (try? verifyModelFolder($0)) != nil }
    }

    private func installedModelFolder(for model: WhisperLocalModel) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base
            .appending(path: "WhisperModels", directoryHint: .isDirectory)
            .appending(path: model.resourceName, directoryHint: .isDirectory)
    }

    private func documentsModelFolder(for model: WhisperLocalModel) -> URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appending(path: "WhisperModels", directoryHint: .isDirectory)
            .appending(path: model.resourceName, directoryHint: .isDirectory)
    }

    private var downloadBaseFolder: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base.appending(path: "WhisperDownloads", directoryHint: .isDirectory)
    }

    private func tempDownloadFolder(for model: WhisperLocalModel) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base
            .appending(path: "WhisperModels", directoryHint: .isDirectory)
            .appending(path: "tmp-\(model.resourceName)", directoryHint: .isDirectory)
    }

    private func localModelCandidates(for model: WhisperLocalModel) -> [URL] {
        var candidates: [URL] = [installedModelFolder(for: model)]
        if let documents = documentsModelFolder(for: model) {
            candidates.append(documents)
        }
        candidates.append(contentsOf: downloadedModelCandidates(for: model))
        return candidates
    }

    private func downloadedModelCandidates(for model: WhisperLocalModel) -> [URL] {
        guard let enumerator = fileManager.enumerator(at: downloadBaseFolder, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return []
        }
        return enumerator
            .compactMap { $0 as? URL }
            .filter { $0.lastPathComponent.localizedCaseInsensitiveContains(model.downloadedFolderHint) || $0.lastPathComponent.localizedCaseInsensitiveContains(model.rawValue) }
            .filter { (try? verifyModelFolder($0)) != nil }
    }

    private func isValidModelFolder(_ url: URL) -> Bool {
        (try? verifyModelFolder(url)) != nil
    }

    private func verifyModelFolder(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path),
              let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey]) else {
            debugLog("Verification failed. Missing folder: \(url.path)")
            throw WhisperModelManagerError.missingModelFiles
        }

        let requiredRelativePaths = [
            "TextDecoder.mlmodelc",
            "TextDecoder.mlmodelc/weights/weight.bin",
            "MelSpectrogram.mlmodelc",
            "AudioEncoder.mlmodelc"
        ]
        var missing = requiredRelativePaths.filter {
            !fileManager.fileExists(atPath: url.appending(path: $0).path)
        }

        var hasTokenizerOrConfig = false
        var fileCount = 0
        for case let fileURL as URL in enumerator {
            fileCount += 1
            let path = fileURL.path.lowercased()
            if path.hasSuffix("tokenizer.json") || path.hasSuffix("config.json") || path.hasSuffix("generation_config.json") {
                hasTokenizerOrConfig = true
            }
        }

        if !hasTokenizerOrConfig {
            missing.append("tokenizer/config files")
        }
        if fileCount == 0 {
            missing.append("model folder contents")
        }

        if !missing.isEmpty {
            debugLog("Verification failed for \(url.path). Missing: \(missing.joined(separator: ", "))")
            throw WhisperModelManagerError.missingRequiredFiles(missing)
        }

        debugLog("Verification succeeded for \(url.path). Files checked: \(fileCount)")
    }

    private func folderSize(_ url: URL) -> UInt64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]) else {
            return 0
        }
        return enumerator.reduce(UInt64(0)) { total, item in
            guard let url = item as? URL,
                  let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true else { return total }
            return total + UInt64(values.fileSize ?? 0)
        }
    }

    private func installedPathKey(for model: WhisperLocalModel) -> String {
        "installedWhisperModelPath.\(model.rawValue)"
    }

    private func verifiedKey(for model: WhisperLocalModel) -> String {
        "verifiedWhisperModel.\(model.rawValue)"
    }

    private func refreshState() {
        if isInstalled(selectedModel) {
            downloadProgress = 1
            downloadedBytes = selectedModel.estimatedBytes
            totalBytes = selectedModel.estimatedBytes
            downloadStatusText = "Ready to listen"
            modelState = .ready
        } else {
            downloadProgress = 0
            downloadedBytes = 0
            totalBytes = selectedModel.estimatedBytes
            downloadStatusText = "Setting up the offline voice model..."
            modelState = .notInstalled
        }
    }

    private func cleanupPartialInstall(for model: WhisperLocalModel) {
        try? fileManager.removeItem(at: installedModelFolder(for: model))
        try? fileManager.removeItem(at: tempDownloadFolder(for: model))
        UserDefaults.standard.removeObject(forKey: installedPathKey(for: model))
        UserDefaults.standard.set(false, forKey: verifiedKey(for: model))
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[WhisperModelManager] \(message)")
        #endif
    }

    private func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteOutOfSpaceError {
            return "There is not enough storage to download the voice model. Please free some space and try again."
        }
        if nsError.domain == NSPOSIXErrorDomain && nsError.code == 28 {
            return "There is not enough storage to download the voice model. Please free some space and try again."
        }
        if error is CancellationError {
            return "Model setup was cancelled."
        }
        if let managerError = error as? WhisperModelManagerError {
            return managerError.localizedDescription
        }
        return "The offline voice model download was incomplete. Please retry with a stable internet connection."
    }
}

enum WhisperLocalModel: String, CaseIterable, Identifiable {
    case tiny
    case base

    var id: String { rawValue }

    var modelName: String {
        switch self {
        case .tiny: return "openai/whisper-tiny"
        case .base: return "openai/whisper-base"
        }
    }

    var resourceName: String {
        modelName.replacingOccurrences(of: "/", with: "-")
    }

    var downloadVariant: String {
        switch self {
        case .tiny: return "openai_whisper-tiny"
        case .base: return "openai_whisper-base"
        }
    }

    var downloadedFolderHint: String {
        downloadVariant
    }

    var title: String {
        switch self {
        case .tiny: return "Whisper Tiny"
        case .base: return "Whisper Base"
        }
    }

    var subtitle: String {
        switch self {
        case .tiny: return "Fastest download, good for quick commands."
        case .base: return "Better accuracy for natural speech."
        }
    }

    var estimatedSize: String {
        switch self {
        case .tiny: return "about 75 MB"
        case .base: return "about 145 MB"
        }
    }

    var estimatedBytes: Int64 {
        switch self {
        case .tiny: return 75 * 1_024 * 1_024
        case .base: return 145 * 1_024 * 1_024
        }
    }

    var estimatedSetupTime: String {
        switch self {
        case .tiny: return "under 1 minute"
        case .base: return "1-2 minutes"
        }
    }

    init?(modelName: String) {
        if modelName.contains("base") {
            self = .base
        } else if modelName.contains("tiny") {
            self = .tiny
        } else {
            return nil
        }
    }
}

enum WhisperModelState: Equatable {
    case notInstalled
    case preparing
    case downloading(progress: Double)
    case verifying
    case installing
    case installed
    case loading
    case ready
    case failed(message: String)
}

enum WhisperModelManagerError: LocalizedError {
    case modelMissing
    case corruptedModel
    case missingModelFiles
    case missingRequiredFiles([String])
    case unsupportedDevice

    var errorDescription: String? {
        switch self {
        case .modelMissing:
            return "The voice model is not installed yet. Download it once, then voice works offline."
        case .corruptedModel:
            return "The downloaded voice model looks incomplete. Please retry the download."
        case .missingModelFiles:
            return "The voice model is missing required files. Please retry the download."
        case .missingRequiredFiles:
            return "The offline voice model download was incomplete. Please retry with a stable internet connection."
        case .unsupportedDevice:
            return "This device may not support local voice transcription smoothly. Try Whisper Tiny."
        }
    }
}
