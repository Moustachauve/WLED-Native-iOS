
import SwiftUI
import WebKit

struct DeviceView: View {
    
    let device: DeviceItem
    
    var body: some View {
        Webview(url: URL(string: "http://\(device.address)")!)
            .navigationTitle(device.name)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeviceView(device: DeviceItem(address: "192.168.10.194"))
        }
    }
}
