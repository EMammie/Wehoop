import DesignSystem
import SwiftUI

@main
struct WehoopApp: App {
    @State private var root: CompositionRoot
    @State private var navigation = AppNavigation()
    @State private var network = NetworkMonitor()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        WehoopFonts.register()
        _root = State(initialValue: CompositionRoot())
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(root: root, navigation: navigation, isOnline: network.isOnline)
                .onOpenURL { navigation.open(url: $0) }
                .task {
                    if let url = root.launchURL { navigation.open(url: url) }
                    network.start { [root] in Task { await root.catchUp() } }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            // Back in the foreground: page /changes for every followed game (reconnect contract step 5).
            if phase == .active { Task { await root.catchUp() } }
        }
    }
}
