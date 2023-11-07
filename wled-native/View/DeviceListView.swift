

import SwiftUI
import CoreData

struct DeviceListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showHiddenDevices: Bool = false
    @State private var addDeviceButtonActive: Bool = false
    
    // TODO: Create a filter object that generates a predicate
    @State private var filter = NSPredicate(format: "isHidden == %@ || isHidden == nil", NSNumber(value: false))
    @State private var sort = [
        NSSortDescriptor(keyPath: \Device.isOnline, ascending: false),
        NSSortDescriptor(keyPath: \Device.name, ascending: true),
    ]
    
    private let discoveryService = DiscoveryService()
    
    init() {
        discoveryService.scan()
    }
    
    var body: some View {
        NavigationView {
            FetchedObjects(predicate: filter, sortDescriptors: sort) { (devices: [Device]) in
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
                .refreshable {
                    await refreshDevices(devices: devices)
                }
                .onAppear(perform: {
                    Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                        refreshDevicesSync(devices: devices)
                    }
                })
            }
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
                    Menu {
                        Button {
                            addDeviceButtonActive = true
                        } label: {
                            Label("Add New Device", systemImage: "plus")
                        }
                        Button {
                            showHiddenDevices = !showHiddenDevices
                            updateFilter()
                        } label: {
                            if (showHiddenDevices) {
                                Label("Hide Hidden Devices", systemImage: "eye.slash")
                            } else {
                                Label("Show Hidden Devices", systemImage: "eye")
                            }
                        }
                    } label: {
                        Label("Add Item", systemImage: "ellipsis.circle")
                    }
                    .background(
                        NavigationLink(destination: DeviceAddView(), isActive: $addDeviceButtonActive) {
                            EmptyView()
                        }
                    )
                    
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            Text("Select an item")
        }
    }
    
    private func updateFilter() {
        filter = NSPredicate(format: "isHidden == %@ || isHidden == nil", NSNumber(value: showHiddenDevices))
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
    private func refreshDevices(devices: [Device]) async {
        let deviceApi = DeviceApi()
        for device in devices {
            deviceApi.updateDevice(device: device, context: viewContext)
        }
        
        discoveryService.scan()
    }
    
    private func refreshDevicesSync(devices: [Device]) {
        Task {
            print("auto-refreshing")
            await refreshDevices(devices: devices)
        }
    }
    
    @Sendable
    private func refreshAndScanDevices(devices: [Device]) async {
        await refreshDevices(devices: devices)
        discoveryService.scan()
    }
}

struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
