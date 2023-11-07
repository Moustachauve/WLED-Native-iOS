
import SwiftUI

struct DeviceView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var device: Device
    
    init(device: Device) {
        self.device = device
    }
    
    var body: some View {
        WebView(url: getDeviceAddress())
            .navigationTitle(device.name ?? "")
            .toolbar {
                NavigationLink {
                    DeviceEditView(device: device)
                } label: {
                    Text(String(localized: "Edit"))
                }
            }
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
