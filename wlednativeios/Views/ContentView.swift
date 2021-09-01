
import SwiftUI

struct ContentView: View {
    var body: some View {
        List(DeviceRepository.instance.getAll(), id: \.address) { deviceItem in
            DeviceListItem(device: deviceItem)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
