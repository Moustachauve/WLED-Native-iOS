
import SwiftUI

@main
struct WLEDNativeApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            DeviceListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear() {
                    refreshVersionsSync()
                }
        }
    }
    
    
    private func refreshVersionsSync() {
        Task {
            print("Refreshing available Releases")
            await ReleaseService().refreshVersions(context: persistenceController.container.viewContext)
        }
    }
}
