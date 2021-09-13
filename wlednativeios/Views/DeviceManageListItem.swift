
import SwiftUI

struct DeviceManageListItem: View {
    var device: DeviceItem
    
    
    @State private var brightness: Double = 50
    @State private var isDeviceOn = true
    
    var body: some View {
        NavigationLink(destination: DeviceView(device: device)) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(device.name != "" ? device.name : "(New Device)")
                                    .font(.title2)
                                    .lineLimit(1)
                                if (device.isHidden) {
                                    Image(systemName: "eye.slash")
                                }
                            }
                            HStack {
                                Text(device.address)
                                    .font(.body)
                                    .lineLimit(1)
                                if (device.isHidden) {
                                    Text("[Hidden]")
                                }
                            }
                        }
                        Spacer()
                        Button {
                            editDevice()
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .padding()
                        Button {
                            deleteDevice()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .padding()
                        .foregroundColor(.red)
                    }
                }
                Spacer()
            }
        }
    }
    
    private func editDevice() {
        print("edit")
    }
    
    private func deleteDevice() {
        print("delete")
    }
}

struct DeviceManageListItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceManageListItem(device: DeviceItem(address: "192.168.10.194", name: "WLED Kitchen"))
            DeviceManageListItem(device: DeviceItem(address: "4.3.2.1", name: "WLED AP", isHidden: true))
        }
        .previewLayout(.fixed(width: 300, height: 80))
    }
}
