

import SwiftUI
import CoreData

struct DeviceListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Device.name, ascending: true)],
        animation: .default)
    private var devices: FetchedResults<Device>
    
    private let discoveryService = DiscoveryService()
    
    init() {
        discoveryService.scan()
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(devices) { device in
                    NavigationLink {
                        DeviceView(device: device)
                    } label: {
                        DeviceListItemView(device: device)
                    }
                    .swipeActions(allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteItems(device: device)
                        } label: {
                            Label(String(localized:"Delete"), systemImage: "trash.fill")
                        }
                        Button {
                            print("TODO: Edit device")
                        } label: {
                            Label(String(localized: "Edit"), systemImage: "pencil")
                        }
                        .tint(.accentColor)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .refreshable(action: refreshDevices)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Image(.wledLogoAkemi)
                            .resizable()
                            .scaledToFit()
                            .padding(2)
                    }
                    .frame(maxWidth: 200)
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            Text("Select an item")
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Device(context: viewContext)
            // TODO: Show new device form
            newItem.name = Date().formatted()
            newItem.address = "192.168.11.101"
            newItem.color = 2552555;

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItems(device: Device) {
        withAnimation {
            viewContext.delete(device)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    @Sendable
    private func refreshDevices() async {
        let deviceApi = DeviceApi()
        for device in devices {
            deviceApi.updateDevice(device: device, context: viewContext)
        }
        
        discoveryService.scan()
    }
}

struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
