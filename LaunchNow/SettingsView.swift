import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SwiftData

struct SettingsView: View {
    @ObservedObject var appStore: AppStore
    @StateObject private var updater = Updater.shared
    @State private var showResetConfirm = false

    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Text("LaunchNow")
                    .font(.title)
                Text("v\(getVersion())")
                    .font(.footnote)
                Spacer()
                Button {
                    appStore.isSetting = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2.bold())
                        .foregroundStyle(.placeholder)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            
            VStack {
                HStack {
                    Text(NSLocalizedString("Style", comment: "Classic Launchpad (Fullscreen)"))
                    Spacer()
                    Toggle(isOn: $appStore.isFullscreenMode) {
                        
                    }
                    .toggleStyle(.switch)
                }
                HStack {
                    Text(NSLocalizedString("ShowAppName", comment: "Show app name"))
                    Spacer()
                    Toggle(isOn: $appStore.showAppNameBelowIcon) {}
                        .toggleStyle(.switch)
                }
                HStack {
                    Text(NSLocalizedString("ScrollSensitivity", comment: "Scrolling sensitivity"))
                    VStack {
                        Slider(value: $appStore.scrollSensitivity, in: 0.01...0.99)
                        HStack {
                            Text(NSLocalizedString("Low", comment: "Low"))
                                .font(.footnote)
                            Spacer()
                            Text(NSLocalizedString("High", comment: "High"))
                                .font(.footnote)
                        }
                    }
                }
                HStack {
                    Text(NSLocalizedString("DisplayedLanguage", comment: "Displayed Language"))
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Localization")!)
                        AppDelegate.shared?.hideWindow()
                    } label: {
                        Text(NSLocalizedString("Language", comment: "Language..."))
                    }
                }
            }
            .padding()
            
            Divider()
            
            HStack {
                Button {
                    exportDataFolder()
                } label: {
                    Label(NSLocalizedString("Export", comment: "Export Data"), systemImage: "square.and.arrow.up")
                }

                Button {
                    importDataFolder()
                } label: {
                    Label(NSLocalizedString("Import", comment: "Import Data"), systemImage: "square.and.arrow.down")
                }
            }
            .padding()
            
            Divider()
            
            HStack {
                Button(NSLocalizedString("CheckUpdates", comment: "Check for Updates")) {
                    Updater.shared.checkForUpdate()
                }
                .alert(updater.alertTitle, isPresented: $updater.showAlert) {
                    if let url = updater.alertURL {
                        Button(NSLocalizedString("Confirm", comment: "Confirm")) {
                            NSWorkspace.shared.open(url)
                            AppDelegate.shared?.hideWindow()
                        }
                        Button(NSLocalizedString("Cancel", comment: "Cancel"), role: .cancel) {}
                    } else {
                        Button(NSLocalizedString("Confirm", comment: "Confirm"), role: .cancel) {}
                    }
                } message: {
                    Text(updater.alertMessage)
                }
                
                Spacer()
                
                Button {
                    appStore.showWelcomeSheet = true
                } label: {
                    Text(NSLocalizedString("ShowWelcome", comment: "Show Introduction"))
                }
                .sheet(isPresented: $appStore.showWelcomeSheet) {
                    WelcomeView(appStore: appStore)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            HStack {
                Button {
                    appStore.refresh()
                } label: {
                    Label(NSLocalizedString("Refresh", comment: "Refresh"), systemImage: "arrow.clockwise")
                }

                Spacer()

                Button {
                    showResetConfirm = true
                } label: {
                    Label(NSLocalizedString("ResetLayout", comment: "Reset Layout"), systemImage: "arrow.counterclockwise")
                        .foregroundStyle(Color.red)
                }
                .alert(NSLocalizedString("ConfirmReset", comment: "Confirm to reset layout?"), isPresented: $showResetConfirm) {
                    Button(NSLocalizedString("Reset", comment: "Reset"), role: .destructive) { appStore.resetLayout() }
                    Button(NSLocalizedString("Cancel", comment: "Cancel"), role: .cancel) {}
                } message: {
                    Text(NSLocalizedString("ResetAlert", comment: "ResetAlert"))
                }
                                
                Button {
                    exit(0)
                } label: {
                    Label(NSLocalizedString("Quit", comment: "Quit"), systemImage: "xmark.circle")
                        .foregroundStyle(Color.red)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)

        }
        .padding()
    }
    
    func getVersion() -> String {
            return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知"
    }
    
    private func showErrorAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Export / Import Application Support Data
    private func supportDirectoryURL() throws -> URL {
        let fm = FileManager.default
        let appSupport = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = appSupport.appendingPathComponent("LaunchNow", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func exportDataFolder() {
        do {
            let sourceDir = try supportDirectoryURL()
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.allowsMultipleSelection = false
            panel.prompt = "Choose"
            panel.message = "Choose a destination folder to export LaunchNow data"
            if panel.runModal() == .OK, let destParent = panel.url {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd_HHmmss"
                let folderName = "LaunchNow_Export_" + formatter.string(from: Date())
                let destDir = destParent.appendingPathComponent(folderName, isDirectory: true)
                try copyDirectory(from: sourceDir, to: destDir)
            }
        } catch {
            LaunchNowLogger.log(.error, category: .general, message: "Failed to export data folder: \(error.localizedDescription)")
            // Show user-friendly error alert
            showErrorAlert(title: "Export Failed", message: "Unable to export LaunchNow data: \(error.localizedDescription)")
        }
    }

    private func importDataFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Import"
        panel.message = "Choose a folder previously exported from LaunchNow"
        if panel.runModal() == .OK, let srcDir = panel.url {
            do {
                // 验证是否为有效的排序数据目录
                guard isValidExportFolder(srcDir) else { return }
                let destDir = try supportDirectoryURL()
                // 若用户选的就是目标目录，跳过
                if srcDir.standardizedFileURL == destDir.standardizedFileURL { return }
                try replaceDirectory(with: srcDir, at: destDir)
                // 导入完成后加载并刷新
                appStore.applyOrderAndFolders()
                appStore.refresh()
            } catch {
                // 忽略错误或可在此添加用户提示
            }
        }
    }

    private func copyDirectory(from src: URL, to dst: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: dst.path) {
            try fm.removeItem(at: dst)
        }
        try fm.copyItem(at: src, to: dst)
    }

    private func replaceDirectory(with src: URL, at dst: URL) throws {
        let fm = FileManager.default
        // 确保父目录存在
        let parent = dst.deletingLastPathComponent()
        if !fm.fileExists(atPath: parent.path) {
            try fm.createDirectory(at: parent, withIntermediateDirectories: true)
        }
        if fm.fileExists(atPath: dst.path) {
            try fm.removeItem(at: dst)
        }
        try fm.copyItem(at: src, to: dst)
    }

    private func isValidExportFolder(_ folder: URL) -> Bool {
        let fm = FileManager.default
        let storeURL = folder.appendingPathComponent("Data.store")
        guard fm.fileExists(atPath: storeURL.path) else { return false }
        // 尝试打开该库并检查是否有排序数据
        do {
            let config = ModelConfiguration(url: storeURL)
            let container = try ModelContainer(for: TopItemData.self, PageEntryData.self, configurations: config)
            let ctx = container.mainContext
            let pageEntries = try ctx.fetch(FetchDescriptor<PageEntryData>())
            if !pageEntries.isEmpty { return true }
            let legacyEntries = try ctx.fetch(FetchDescriptor<TopItemData>())
            return !legacyEntries.isEmpty
        } catch {
            return false
        }
    }
}
