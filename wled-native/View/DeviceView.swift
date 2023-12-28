
import SwiftUI

struct DeviceView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var device: Device
    
    var body: some View {
        TabView {
            WebView(url: getDeviceAddress())
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Controls")
                }
            DeviceEditView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .badge((device.latestUpdateVersionTagAvailable ?? "").isEmpty ? 0 : 1)
        }
        .navigationTitle(getDeviceName())
        .navigationBarTitleDisplayMode(.inline)
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
        
        return DeviceView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(device)
    }
}
