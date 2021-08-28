
import SwiftUI

struct DeviceList: View {
    var body: some View {
        List([DeviceItem(address: "192.168.10.194", name: "WLED")], id: \.address) { deviceItem in
            DeviceListItem(device: deviceItem)
            
        }
    }
}

struct DeviceList_Previews: PreviewProvider {
    static var previews: some View {
        DeviceList()
    }
}
