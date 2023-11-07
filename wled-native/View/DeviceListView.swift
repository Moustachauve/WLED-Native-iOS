

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
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .refreshable(action: refreshAndScanDevices)
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
                    NavigationLink {
                        DeviceAddView()
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            Text("Select an item")
        }
        .onAppear(perform: {
            Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                refreshDevicesSync()
            }
            
        })
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
    
    private func refreshDevicesSync() {
        Task {
            await refreshDevices()
        }
    }
    
    @Sendable
    private func refreshAndScanDevices() async {
        await refreshDevices()
        discoveryService.scan()
    }
}

struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
