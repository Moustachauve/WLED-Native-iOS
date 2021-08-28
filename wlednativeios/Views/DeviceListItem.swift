
import SwiftUI

struct DeviceListItem: View {
    var device: DeviceItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.title2)
                    .lineLimit(1)
                Text(device.address)
                    .font(.body)
                    .lineLimit(1)
                    
            }
            Spacer()
        }
    }
}

struct DeviceListItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceListItem(device: DeviceItem(address: "192.168.10.194", name: "WLED Kitchen"))
            DeviceListItem(device: DeviceItem(address: "4.3.2.1", name: "WLED AP"))
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
