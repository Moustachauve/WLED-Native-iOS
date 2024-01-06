

import SwiftUI
import CoreData

struct DeviceListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var addDeviceButtonActive: Bool = false
    
    @State private var firstLoad = true
    
    @StateObject private var filter = DeviceListFilterAndSort(showHiddenDevices: false)
    private let discoveryService = DiscoveryService()
    
    var body: some View {
        NavigationView {
            FetchedObjects(predicate: filter.getOnlineFilter(), sortDescriptors: filter.getSortDescriptors()) { (devices: [Device]) in
                FetchedObjects(predicate: filter.getOfflineFilter(), sortDescriptors: filter.getSortDescriptors()) { (devicesOffline: [Device]) in
                    List {
                        ForEach(devices, id: \.tag) { device in
                            NavigationLink {
                                DeviceView()
                                    .environmentObject(device)
                            } label: {
                                DeviceListItemView()
                                    .environmentObject(device)
                            }
                            .environmentObject(device)
                            .swipeActions(allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteItems(device: device)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                        }
                        Section(header: Text("Offline Devices")) {
                            ForEach(devicesOffline, id: \.tag) { device in
                                NavigationLink {
                                    DeviceView()
                                        .environmentObject(device)
                                } label: {
                                    DeviceListItemView()
                                        .environmentObject(device)
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
                        .opacity(devicesOffline.count > 0 ? 1 : 0)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await refreshDevices(devices: devices + devicesOffline)
                        discoveryService.scan()
                    }
                    .onAppear(perform: {
                        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                            refreshDevicesSync(devices: devices + devicesOffline)
                        }
                        Task {
                            print("Initial refresh and scan")
                            await refreshDevices(devices: devices + devicesOffline)
                            discoveryService.scan()
                        }
                    })
                }
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
                        Section {
                            Button {
                                addDeviceButtonActive.toggle()
                            } label: {
                                Label("Add New Device", systemImage: "plus")
                            }
                            Button {
                                withAnimation {
                                    filter.showHiddenDevices = !filter.showHiddenDevices
                                }
                            } label: {
                                if (filter.showHiddenDevices) {
                                    Label("Hide Hidden Devices", systemImage: "eye.slash")
                                } else {
                                    Label("Show Hidden Devices", systemImage: "eye")
                                }
                            }
                        }
                        Section {
                            Link(destination: URL(string: "https://kno.wled.ge/")!) {
                                Label("WLED Documentation", systemImage: "questionmark.circle")
                            }
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $addDeviceButtonActive, content: DeviceAddView.init)
            VStack {
                Text("Select A Device")
                    .font(.title2)
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
    private func refreshDevices(devices: [Device]) async {
        let deviceApi = DeviceApi()
        await withTaskGroup(of: Void.self) { [self] group in
            for device in devices {
                // Don't start a refresh request when the device is not done refreshing.
                if (!self.firstLoad && device.isRefreshing) {
                    continue
                }
                group.addTask {
                    await viewContext.performAndWait {
                        device.isRefreshing = true
                    }
                    await deviceApi.updateDevice(device: device, context: viewContext)
                }
            }
            self.firstLoad = false
        }
    }
    
    private func refreshDevicesSync(devices: [Device]) {
        Task {
            print("auto-refreshing")
            await refreshDevices(devices: devices)
        }
    }
}

struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
