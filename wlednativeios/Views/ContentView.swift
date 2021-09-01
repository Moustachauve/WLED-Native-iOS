
import SwiftUI

struct ContentView: View {
    var deviceList = DeviceRepository.instance.getAll()
    
    var body: some View {
        NavigationView {
            List(deviceList, id: \.address) {
                deviceItem in DeviceListItem(device: deviceItem)
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    Image("wled_logo_akemi")
                }
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(deviceList: [
                DeviceItem(address: "192.168.10.194", name: "WLED Bedroom"),
                DeviceItem(address: "192.168.10.195", name: "WLED Kitchen"),
                DeviceItem(address: "192.168.10.196", name: "WLED Kitchen 2")
            ])
        }
    }
}
