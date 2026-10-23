import DesignSystem
import SwiftUI

@main
struct WehoopApp: App {
    private let root: CompositionRoot

    init() {
        WehoopFonts.register()
        root = CompositionRoot()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(tabs: root.tabs)
        }
    }
}
