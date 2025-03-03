import Network
//import SwiftUI
import Combine
public class NetworkManager: ObservableObject {
    private var monitor: NWPathMonitor
    private var queue: DispatchQueue
    @Published var isNetworkReachable: Bool = true
    public static let shared = NetworkManager()
    private init() {
        // Initialize the network monitor
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "NetworkMonitorQueue")
        // Start monitoring the network path
        monitor.pathUpdateHandler = { [weak self] path in
            // Check the network status and update the property
            DispatchQueue.main.async {
                self?.isNetworkReachable = path.status == .satisfied
            }
        }
        // Start monitoring on a background thread
        monitor.start(queue: queue)
    }
    deinit {
        // Stop monitoring when the object is deinitialized
        monitor.cancel()
    }
    // A helper function to check the current network status
    public func checkNetworkStatus() -> Bool {
        return isNetworkReachable
    }
}
