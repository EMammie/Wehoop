//
//  BundleDiagnostics.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
@testable import Wehoop

/// Helper to diagnose bundle and resource access issues in tests
enum BundleDiagnostics {
    static func printBundleInfo() {
        print("=== Bundle Diagnostics ===")
        print("Main Bundle Identifier: \(Bundle.main.bundleIdentifier ?? "nil")")
        print("Main Bundle Path: \(Bundle.main.bundlePath)")
        print("Main Bundle Resource Path: \(Bundle.main.resourcePath ?? "nil")")
        
        // Check for games.json in various locations
        let testPaths = [
            ("Main bundle with subdirectory", Bundle.main.url(forResource: "games", withExtension: "json", subdirectory: "MockData")),
            ("Main bundle without subdirectory", Bundle.main.url(forResource: "games", withExtension: "json", subdirectory: nil)),
            ("Using findResource with subdirectory", Bundle.main.findResource(name: "games", extension: "json", subdirectory: "MockData")),
            ("Using findResource without subdirectory", Bundle.main.findResource(name: "games", extension: "json", subdirectory: nil))
        ]
        
        print("\n--- Games.json lookup attempts ---")
        for (description, url) in testPaths {
            if let url = url {
                print("✓ \(description): \(url.path)")
            } else {
                print("✗ \(description): Not found")
            }
        }
        
        // List all bundles
        print("\n--- All Bundles ---")
        for (index, bundle) in Bundle.allBundles.enumerated() {
            print("Bundle \(index): \(bundle.bundleIdentifier ?? "no identifier") - \(bundle.bundlePath)")
            if let resourcePath = bundle.resourcePath {
                print("  Resource Path: \(resourcePath)")
                // Check if MockData directory exists
                let mockDataPath = "\(resourcePath)/MockData"
                if FileManager.default.fileExists(atPath: mockDataPath) {
                    print("  ✓ MockData directory exists")
                    if let contents = try? FileManager.default.contentsOfDirectory(atPath: mockDataPath) {
                        print("  Contents: \(contents.joined(separator: ", "))")
                    }
                } else {
                    print("  ✗ MockData directory does not exist")
                }
            }
        }
        
        // Try to find app bundle
        print("\n--- App Bundle Search ---")
        let testBundleId = Bundle.main.bundleIdentifier ?? ""
        let possibleAppIds = [
            testBundleId.replacingOccurrences(of: "Tests", with: ""),
            testBundleId.replacingOccurrences(of: ".Tests", with: ""),
            "com.wehoop.Wehoop"
        ]
        
        for appId in possibleAppIds where !appId.isEmpty {
            if let appBundle = Bundle(identifier: appId) {
                print("✓ Found app bundle: \(appId)")
                print("  Path: \(appBundle.bundlePath)")
                if let resourcePath = appBundle.resourcePath {
                    print("  Resource Path: \(resourcePath)")
                    if let url = appBundle.findResource(name: "games", extension: "json", subdirectory: "MockData") {
                        print("  ✓ Found games.json: \(url.path)")
                    } else {
                        print("  ✗ games.json not found")
                    }
                }
            } else {
                print("✗ App bundle not found: \(appId)")
            }
        }
        
        print("=== End Diagnostics ===")
    }
}
