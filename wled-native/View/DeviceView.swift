
import SwiftUI

struct DeviceView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var device: Device
    
    @State private var selectedPage = 0
    
    @State var showDownloadFinished = false
    @State var shouldWebViewRefresh = false
    
    var body: some View {
        TabView(selection: $selectedPage) {
            ZStack {
                WebView(url: getDeviceAddress(), reload: $shouldWebViewRefresh) { filePathDestination in
                    withAnimation {
                        showDownloadFinished = true
                        Task {
                            try await Task.sleep(nanoseconds: UInt64(3 * Double(NSEC_PER_SEC)))
                            showDownloadFinished = false
                        }
                    }
                }
                if (showDownloadFinished) {
                    VStack {
                        Spacer()
                        Text("Download Completed")
                            .font(.title3)
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(15)
                            .padding(.bottom)
                    }
                }
            }
            .tag(0)
            .tabItem {
                Image(systemName: "slider.horizontal.3")
                Text("Controls")
            }
            DeviceEditView()
                .tag(1)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .badge((device.latestUpdateVersionTagAvailable ?? "").isEmpty ? 0 : 1)
        }
        .navigationTitle(getDeviceName())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if selectedPage == 0 {
                    Button {
                        shouldWebViewRefresh = true
                        print(selectedPage)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
    
    func getDeviceAddress() -> URL? {
        guard let deviceAddress = device.address else {
            return nil
        }
        return URL(string: "http://\(deviceAddress)")!
    }
    
    private func getDeviceName() -> String {
        guard let name = device.name, !name.isEmpty else {
            return String(localized: "(New Device)")
        }
        return name
    }
}

struct DeviceView_Previews: PreviewProvider {
    static let device = Device(context: PersistenceController.preview.container.viewContext)
    
    static var previews: some View {
        device.tag = UUID()
        device.name = ""
        device.address = "google.com"
        device.isOnline = true
        device.networkRssi = -80
        device.color = 6244567779
        device.brightness = 125
        
        return NavigationView{
            DeviceView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(device)
        }
    }
}
