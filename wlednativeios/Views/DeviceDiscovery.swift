
import SwiftUI

struct DeviceDiscovery: View {
    
    
    var deviceList = [DeviceItem]()
    
    var body: some View {
        VStack {
            ForEach(deviceList, id: \.address) { deviceItem in
                VStack {
                    DeviceListItem(device: deviceItem)
                    Divider()
                }
                .padding(.horizontal, 8)
            }
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2)
                .padding()
                
            Spacer()
            
                
            .navigationTitle("Looking for Devices")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DeviceDiscovery()) {
                        Button {
                            
                        } label: {
                            Image(systemName: "plus")
                            Text("Add Manually")
                        }
                    }
                }
            }
        }
    }
}

struct DeviceDiscovery_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeviceDiscovery(deviceList: [
                DeviceItem(address: "192.168.10.194", name: "WLED Bedroom"),
                DeviceItem(address: "192.168.10.195", name: "WLED Kitchen"),
                DeviceItem(address: "192.168.10.196", name: "WLED Kitchen 2")
            ])
        }
    }
}
