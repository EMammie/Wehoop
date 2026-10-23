//
//  Bundle+Resources.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

extension Bundle {
    /// Finds a resource URL trying multiple strategies
    /// This handles cases where resources might be in different locations in test vs app bundles
    func findResource(name: String, extension ext: String, subdirectory: String?) -> URL? {
        // Strategy 1: Try with subdirectory as specified
        if let subdirectory = subdirectory,
           let url = url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return url
        }
        
        // Strategy 2: Try without subdirectory (files might be at bundle root)
        if let url = url(forResource: name, withExtension: ext, subdirectory: nil) {
            return url
        }
        
        // Strategy 3: Try constructing path manually (for cases where bundle structure differs)
        if let resourcePath = resourcePath {
            let pathsToTry: [String]
            if let subdirectory = subdirectory {
                pathsToTry = [
                    "\(resourcePath)/\(subdirectory)/\(name).\(ext)",
                    "\(resourcePath)/\(name).\(ext)"
                ]
            } else {
                pathsToTry = ["\(resourcePath)/\(name).\(ext)"]
            }
            
            for path in pathsToTry {
                if FileManager.default.fileExists(atPath: path) {
                    return URL(fileURLWithPath: path)
                }
            }
        }
        
        return nil
    }
    
    /// Finds the bundle containing the specified resource file
    /// This is useful for tests where resources might be in a different bundle
    static func resourceBundle(for resourceName: String, withExtension ext: String, subdirectory: String? = nil) -> Bundle? {
        // Strategy 1: Try main bundle (test bundle in tests, app bundle in app)
        if Bundle.main.findResource(name: resourceName, extension: ext, subdirectory: subdirectory) != nil {
            return Bundle.main
        }
        
        // Strategy 2: Try to find the app bundle
        // In tests, the app bundle is typically a dependency
        let testBundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let possibleAppIdentifiers = [
            testBundleIdentifier.replacingOccurrences(of: "Tests", with: ""),
            testBundleIdentifier.replacingOccurrences(of: ".Tests", with: ""),
            "com.wehoop.Wehoop"
        ]
        
        for identifier in possibleAppIdentifiers where !identifier.isEmpty {
            if let appBundle = Bundle(identifier: identifier),
               appBundle.findResource(name: resourceName, extension: ext, subdirectory: subdirectory) != nil {
                return appBundle
            }
        }
        
        // Strategy 3: Search all loaded bundles
        let allBundles = Bundle.allBundles + Bundle.allFrameworks
        
        for bundle in allBundles {
            if bundle == Bundle.main { continue }
            
            if bundle.findResource(name: resourceName, extension: ext, subdirectory: subdirectory) != nil {
                return bundle
            }
        }
        
        // Fallback to main bundle
        return .main
    }
    
    /// Convenience method to get the bundle for MockData resources
    static var mockDataBundle: Bundle {
        // Strategy 1: Try to find the bundle containing games.json in MockData subdirectory
        if let bundle = resourceBundle(for: "games", withExtension: "json", subdirectory: "MockData") {
            return bundle
        }
        
        // Strategy 2: If not found, try without subdirectory (in case files are at bundle root)
        if let bundle = resourceBundle(for: "games", withExtension: "json", subdirectory: nil) {
            return bundle
        }
        
        // Strategy 3: In tests, try to access the app bundle directly
        // The app bundle should be in allBundles when running tests
        let allBundles = Bundle.allBundles + Bundle.allFrameworks
        for bundle in allBundles {
            // Skip test bundles
            if bundle.bundleIdentifier?.contains("Tests") == true { continue }
            // Skip system bundles
            if bundle.bundlePath.contains("/System") || bundle.bundlePath.contains("/Library") { continue }
            
            // Check if this bundle has the games.json file
            if bundle.findResource(name: "games", extension: "json", subdirectory: "MockData") != nil {
                return bundle
            }
        }
        
        // Strategy 4: Try using Bundle(for:) with a class from the app target
        // This should give us the app bundle in tests
        if let appBundle = Bundle(for: MockRemoteDataSource.self) as Bundle?,
           appBundle != Bundle.main,
           appBundle.findResource(name: "games", extension: "json", subdirectory: "MockData") != nil {
            return appBundle
        }
        
        // Final fallback - return main bundle (which is test bundle in tests, app bundle in app)
        return .main
    }
}
