import Foundation
import os.log

/// Centralized logging system for LaunchNow
enum LaunchNowLogger {
    private static let subsystem = "com.launchnow.app"
    
    static let general = Logger(subsystem: subsystem, category: "General")
    static let appScanning = Logger(subsystem: subsystem, category: "AppScanning")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let performance = Logger(subsystem: subsystem, category: "Performance")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// Log levels for different types of messages
    enum Level {
        case debug, info, warning, error, fault
    }
    
    /// Helper method to log with context
    static func log(_ level: Level, category: Logger, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let context = "[\(filename):\(line)] \(function)"
        let fullMessage = "\(context) - \(message)"
        
        switch level {
        case .debug:
            category.debug("\(fullMessage)")
        case .info:
            category.info("\(fullMessage)")
        case .warning:
            category.warning("\(fullMessage)")
        case .error:
            category.error("\(fullMessage)")
        case .fault:
            category.fault("\(fullMessage)")
        }
    }
}