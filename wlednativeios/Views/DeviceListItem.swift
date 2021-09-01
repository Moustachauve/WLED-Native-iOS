
import SwiftUI

struct DeviceListItem: View {
    var device: DeviceItem
    
    @State private var brightness: Double = 50
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name != "" ? device.name : "(New Device)")
                    .font(.title2)
                    .lineLimit(1)
                Text(device.address)
                    .font(.body)
                    .lineLimit(1)
                Slider(
                    value: $brightness,
                    in: 0...255
                )
                    
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
        .previewLayout(.fixed(width: 300, height: 110))
    }
}
