import Network
import Observation

/// Whether the device has a usable network path. A transition back to online is the app's
/// "network change" for the reconnect contract (catch up every followed game).
@Observable
final class NetworkMonitor {
    private(set) var isOnline = true
    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private var onReconnect: (() -> Void)?

    func start(onReconnect: @escaping () -> Void) {
        self.onReconnect = onReconnect
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.update(online: online) }
        }
        monitor.start(queue: .main)
    }

    private func update(online: Bool) {
        let cameBack = online && !isOnline
        isOnline = online
        if cameBack { onReconnect?() }
    }

    deinit { monitor.cancel() }
}
