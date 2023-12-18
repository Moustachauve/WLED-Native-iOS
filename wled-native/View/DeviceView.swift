
import SwiftUI

struct DeviceView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var device: Device
    
    init(device: Device) {
        self.device = device
    }
    
    var body: some View {
        TabView {
            WebView(url: getDeviceAddress())
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Controls")
                }
            DeviceEditView(device: device)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .navigationTitle(device.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func getDeviceAddress() -> URL? {
        guard let deviceAddress = device.address else {
            return nil
        }
        return URL(string: "http://\(deviceAddress)")!
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        
        let device = Device(context: PersistenceController.preview.container.viewContext)
        device.tag = UUID()
        device.name = ""
        device.address = "google.com"
        device.isOnline = true
        device.networkRssi = -80
        device.color = 6244567779
        device.brightness = 125
        
        
        return DeviceView(device: device)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
