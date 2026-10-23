//
//  Logger.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import os.log

/// Centralized logging utility
enum Logger {
    static func debug(_ message: String) {
        os_log("%{public}@", log: .default, type: .debug, message)
    }
    
    static func info(_ message: String) {
        os_log("%{public}@", log: .default, type: .info, message)
    }
    
    static func error(_ message: String) {
        os_log("%{public}@", log: .default, type: .error, message)
    }
}
