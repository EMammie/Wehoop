// swift-tools-version: 6.2
// WehoopKit: every module of the Wehoop app except the app target itself.
// Dependency rules (docs/M5-PLAN.md, "Modules and dependency rules") are enforced
// by scripts/check-deps.sh in CI. Change them there and in the plan, not only here.
import PackageDescription

/// Domain, Contracts, LiveEngine, WehoopData and TestSupport stay nonisolated (no setting).
/// Swift 6 language mode (complete strict concurrency) is set package-wide below.
/// UI modules (DesignSystem, Feature*) default every declaration to the main actor.
let mainActorDefault: [SwiftSetting] = [.defaultIsolation(MainActor.self)]

let features = [
    "FeatureScores", "FeatureGame", "FeaturePlayers", "FeatureTeams",
    "FeatureStandings", "FeatureLeaders", "FeatureFavorites",
    "FeatureOnboarding", "FeatureSettings",
]

var targets: [Target] = [
    .target(name: "Domain"),
    .target(name: "Contracts"),
    .target(name: "LiveEngine", dependencies: ["Domain", "Contracts"]),
    // supabase-swift (exact pin) joins WehoopData in S3.
    .target(name: "WehoopData", dependencies: ["Domain", "Contracts", "LiveEngine"]),
    .target(
        name: "DesignSystem",
        resources: [.copy("Resources/Fonts")],
        swiftSettings: mainActorDefault
    ),
    .target(
        name: "TestSupport",
        dependencies: ["Domain", "Contracts", "LiveEngine"],
        resources: [.copy("Fixtures")]   // golden JSON captured by wehoop-api `pnpm golden` (scripts/sync-goldens.sh)
    ),

    .testTarget(name: "DomainTests", dependencies: ["Domain"]),
    .testTarget(name: "ContractsTests", dependencies: ["Contracts"]),
    .testTarget(name: "LiveEngineTests", dependencies: ["LiveEngine", "TestSupport"]),
    .testTarget(name: "WehoopDataTests", dependencies: ["WehoopData", "TestSupport"]),
    .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"], swiftSettings: mainActorDefault),
    .testTarget(name: "TestSupportTests", dependencies: ["TestSupport"]),
]

for feature in features {
    // Feature* -> Domain, DesignSystem only. Never WehoopData, never another Feature.
    targets.append(.target(name: feature, dependencies: ["Domain", "DesignSystem"], swiftSettings: mainActorDefault))
    targets.append(.testTarget(name: "\(feature)Tests", dependencies: [.target(name: feature)], swiftSettings: mainActorDefault))
}

let libraries = ["Domain", "Contracts", "LiveEngine", "WehoopData", "DesignSystem", "TestSupport"] + features

let package = Package(
    name: "WehoopKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: libraries.map { .library(name: $0, targets: [$0]) },
    targets: targets,
    swiftLanguageModes: [.v6]
)
