

import SwiftUI
import CoreData

//  This helper class creates the correct `DeviceListView` depending on the iOS version
struct DeviceListViewFabric {
    @ViewBuilder
    static func make() -> some View {
        if #available(iOS 16.0, macOS 13, tvOS 16.0, watchOS 9.0, *) {
            DeviceListView()
        } else {
            OldDeviceListView()
        }
    }
}

@available(iOS 16.0, macOS 13, tvOS 16.0, watchOS 9.0, *)
struct DeviceListView: View {
    
    private static let sort = [
        SortDescriptor(\Device.name, comparator: .localized, order: .forward)
    ]
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: sort, animation: .default)
    private var devices: FetchedResults<Device>
    
    @FetchRequest(sortDescriptors: sort, animation: .default)
    private var devicesOffline: FetchedResults<Device>
    
    @State private var timer: Timer? = nil
    
    @State private var selection: Device? = nil
    
    @State private var addDeviceButtonActive: Bool = false
    
    @SceneStorage("DeviceListView.showHiddenDevices") private var showHiddenDevices: Bool = false
    @SceneStorage("DeviceListView.showOfflineDevices") private var showOfflineDevices: Bool = true
    
    private let discoveryService = DiscoveryService()
    
    //MARK: - UI
    
    var body: some View {
        NavigationSplitView {
            list
                .toolbar{ toolbar }
                .sheet(isPresented: $addDeviceButtonActive, content: DeviceAddView.init)
                .navigationBarTitleDisplayMode(.inline)
        } detail: {
            detailView
        }
            .onAppear(perform: appearAction)
            .onDisappear(perform: disappearAction)
            .onChange(of: showHiddenDevices) { _ in updateFilter() }
            .onChange(of: showOfflineDevices) { _ in updateFilter() }
    }
    
    var list: some View {
        List(selection: $selection) {
            Section(header: Text("Online Devices")) {
                sublist(devices: devices)
            }
            if !devicesOffline.isEmpty && showOfflineDevices {
                Section(header: Text("Offline Devices")) {
                    sublist(devices: devicesOffline)
                }
            }
        }
            .listStyle(PlainListStyle())
            .refreshable(action: refreshList)
    }
    
    private func sublist(devices: FetchedResults<Device>) -> some View {
        ForEach(devices) { device in
            NavigationLink(value: device) {
                DeviceListItemView()
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
    }
    
    @ViewBuilder
    private var detailView: some View {
        if let device = selection {
            NavigationStack {
                DeviceView()
            }
                .environmentObject(device)
        } else {
            Text("Select A Device")
                .font(.title2)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
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
                    addButton
                }
                Section {
                    visibilityButton
                    hideOfflineButton
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
    
    var addButton: some View {
        Button {
            addDeviceButtonActive.toggle()
        } label: {
            Label("Add New Device", systemImage: "plus")
        }
    }
    
    var visibilityButton: some View {
        Button {
            withAnimation {
                showHiddenDevices.toggle()
            }
        } label: {
            if (showHiddenDevices) {
                Label("Hide Hidden Devices", systemImage: "eye.slash")
            } else {
                Label("Show Hidden Devices", systemImage: "eye")
            }
        }
    }
    
    var hideOfflineButton: some View {
        Button {
            withAnimation {
                showOfflineDevices.toggle()
            }
        } label: {
            if (showOfflineDevices) {
                Label("Hide Offline Devices", systemImage: "wifi")
            } else {
                Label("Show Offline Devices", systemImage: "wifi.slash")
            }
        }
    }
    
    //MARK: - Actions
    
    @Sendable
    private func refreshList() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await discoveryService.scan() }
            group.addTask { await refreshDevices() }
        }
    }
    
    private func updateFilter() {
        print("Update Filter")
        if showHiddenDevices {
            devices.nsPredicate = NSPredicate(format: "isOnline == %@", NSNumber(value: true))
            devicesOffline.nsPredicate =  NSPredicate(format: "isOnline == %@", NSNumber(value: false))
        } else {
            devices.nsPredicate = NSPredicate(format: "isOnline == %@ AND isHidden == %@", NSNumber(value: true), NSNumber(value: false))
            devicesOffline.nsPredicate =  NSPredicate(format: "isOnline == %@ AND isHidden == %@", NSNumber(value: false), NSNumber(value: false))
        }
    }
    
    //  Instead of using a timer, use the WebSocket API to get notified about changes
    //  Cancel the connection if the view disappears and reconnect as soon it apears again
    private func appearAction() {
        updateFilter()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                print("auto-refreshing")
                await refreshList()
                await refreshDevices()
            }
        }
        discoveryService.scan()
    }
    
    private func disappearAction() {
        timer?.invalidate()
    }
    
    @Sendable
    private func refreshDevices() async {
        await withTaskGroup(of: Void.self) { group in
            devices.forEach { refreshDevice(device: $0, group: &group) }
            devicesOffline.forEach { refreshDevice(device: $0, group: &group) }
        }
    }
    
    private func refreshDevice(device: Device, group: inout TaskGroup<Void>) {
        // Don't start a refresh request when the device is not done refreshing.
        if (!device.isRefreshing) {
            return
        }
        group.addTask {
            await self.viewContext.performAndWait {
                device.isRefreshing = true
            }
            await device.requestManager.addRequest(WLEDRefreshRequest(context: viewContext))
        }
    }
    
    private func deleteItems(device: Device) {
        withAnimation {
            viewContext.delete(device)
            do {
                if viewContext.hasChanges {
                    try viewContext.save()
                }
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

@available(iOS 16.0, macOS 13, tvOS 16.0, watchOS 9.0, *)
#Preview("iOS 16") {
    DeviceListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

    
//MARK: - OLD iOS 15

@available(iOS, deprecated: 16, message: "This implementaion is only for iOS 15 to support the old UI.")
struct OldDeviceListView: View {
    
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
                    await device.requestManager.addRequest(WLEDRefreshRequest(context: viewContext))
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

@available(iOS, deprecated: 16, message: "This implementaion is only for iOS 15 to support the old UI.")
class DeviceListFilterAndSort: ObservableObject {
    
    @Published var showHiddenDevices: Bool
    @Published private var sort = [
        NSSortDescriptor(keyPath: \Device.isOnline, ascending: false),
        NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:))),
    ]

    init(showHiddenDevices: Bool) {
        self.showHiddenDevices = showHiddenDevices
    }
    
    func getSortDescriptors() -> [NSSortDescriptor] {
        return sort
    }
    
    func getOnlineFilter() -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            getOnlineFilter(isOnline: true),
            getHiddenFilterFormat()
        ])
    }
    
    func getOfflineFilter() -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            getOnlineFilter(isOnline: false),
            getHiddenFilterFormat()
        ])
    }
    
    private func getOnlineFilter(isOnline: Bool) -> NSPredicate {
        return NSPredicate(format: "isOnline == %@", NSNumber(value: isOnline))
    }
    
    private func getHiddenFilterFormat() -> NSPredicate {
        if (showHiddenDevices) {
            return NSPredicate(value: true)
        }
        
        return NSPredicate(format: "isHidden == %@", NSNumber(value: false))
    }
}

@available(iOS, deprecated: 16, message: "This implementaion is only for iOS 15 to support the old UI.")
#Preview("iOS 15") {
    OldDeviceListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
