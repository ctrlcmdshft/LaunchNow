import Foundation

/// Constants used throughout the LaunchNow application
enum LaunchNowConstants {
    // MARK: - Layout Constants
    enum Layout {
        static let itemsPerPage: Int = 35
        static let columns: Int = 7
        static let rows: Int = 5
        static let maxBounce: CGFloat = 80
        static let pageSpacing: CGFloat = 100
        static let rowSpacing: CGFloat = 16
        static let columnSpacing: CGFloat = 24
    }
    
    // MARK: - Animation Constants
    enum Animation {
        static let doubleTapThreshold: TimeInterval = 0.3
        static let folderCreateDwell: TimeInterval = 0
        static let autoFlipInterval: TimeInterval = 0.8
    }
    
    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let isFullscreenMode = "isFullscreenMode"
        static let scrollSensitivity = "scrollSensitivity"
        static let showAppNameBelowIcon = "showAppNameBelowIcon"
        static let isStartOnLogin = "isStartOnLogin"
    }
    
    // MARK: - Paths
    enum Paths {
        static let applicationSearchPaths: [String] = [
            "/Applications",
            "\(NSHomeDirectory())/Applications",
            "/System/Applications",
            "/System/Cryptexes/App/System/Applications"
        ]
    }
    
    // MARK: - Performance
    enum Performance {
        static let fullRescanThreshold: Int = 50
        static let debounceInterval: TimeInterval = 0.5
        static let refreshDelay: TimeInterval = 0.1
    }
}