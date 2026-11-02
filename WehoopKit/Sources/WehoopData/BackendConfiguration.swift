import Foundation

/// Where the app's backend lives. The anon key is Supabase's public client key (it grants
/// only what row-level security allows); it still never appears in logs or descriptions.
public struct BackendConfiguration: Sendable, CustomStringConvertible, CustomReflectable {
    /// wehoop-api (`/v1/...`).
    public let apiBaseURL: URL
    /// Supabase (PostgREST, Realtime, Auth).
    public let supabaseURL: URL
    public let anonKey: String

    public init(apiBaseURL: URL, supabaseURL: URL, anonKey: String) {
        self.apiBaseURL = apiBaseURL
        self.supabaseURL = supabaseURL
        self.anonKey = anonKey
    }

    public enum Problem: Error, Equatable {
        case missing(String)
        case invalidURL(String)
    }

    /// Reads `WEHOOP_API_URL`, `WEHOOP_SUPABASE_URL` and `WEHOOP_SUPABASE_ANON_KEY`.
    public static func from(environment: [String: String]) throws -> BackendConfiguration {
        func value(_ name: String) throws -> String {
            guard let raw = environment[name]?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else {
                throw Problem.missing(name)
            }
            return raw
        }
        func url(_ name: String) throws -> URL {
            let raw = try value(name)
            guard let url = URL(string: raw), let scheme = url.scheme, ["http", "https"].contains(scheme), url.host != nil else {
                throw Problem.invalidURL(name)
            }
            return url
        }
        return try BackendConfiguration(
            apiBaseURL: url("WEHOOP_API_URL"),
            supabaseURL: url("WEHOOP_SUPABASE_URL"),
            anonKey: value("WEHOOP_SUPABASE_ANON_KEY")
        )
    }

    public var description: String {
        "BackendConfiguration(api: \(apiBaseURL.absoluteString), supabase: \(supabaseURL.absoluteString), anonKey: <redacted>)"
    }

    /// `dump` and the debugger show the URLs only.
    public var customMirror: Mirror {
        Mirror(self, children: ["apiBaseURL": apiBaseURL, "supabaseURL": supabaseURL, "anonKey": "<redacted>"])
    }
}
