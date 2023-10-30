
import SwiftUI

@main
struct WLEDNativeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            DeviceListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
