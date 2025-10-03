import Foundation
import AppKit

/// Dedicated class for scanning applications to reduce AppStore responsibilities
final class ApplicationScanner {
    static let shared = ApplicationScanner()
    
    private let applicationSearchPaths: [String] = [
        "/Applications",
        "\(NSHomeDirectory())/Applications",
        "/System/Applications",
        "/System/Cryptexes/App/System/Applications"
    ]
    
    private init() {}
    
    /// Scans for applications in all configured paths
    /// - Parameter completion: Completion handler with found applications
    func scanApplications(completion: @escaping ([AppInfo]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let found = self.performScan()
            let sorted = found.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            DispatchQueue.main.async {
                completion(sorted)
            }
        }
    }
    
    private func performScan() -> [AppInfo] {
        var found: [AppInfo] = []
        var seenPaths = Set<String>()
        
        for path in applicationSearchPaths {
            let url = URL(fileURLWithPath: path)
            
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }
            
            for case let item as URL in enumerator {
                let resolved = item.resolvingSymlinksInPath()
                guard resolved.pathExtension == "app",
                      isValidApp(at: resolved),
                      !isInsideAnotherApp(resolved),
                      !seenPaths.contains(resolved.path) else { continue }
                
                seenPaths.insert(resolved.path)
                found.append(AppInfo.from(url: resolved))
            }
        }
        
        return found
    }
    
    private func isValidApp(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    private func isInsideAnotherApp(_ url: URL) -> Bool {
        let pathComponents = url.pathComponents
        for i in 0..<(pathComponents.count - 1) {
            let component = pathComponents[i]
            if component.hasSuffix(".app") {
                return true
            }
        }
        return false
    }
}