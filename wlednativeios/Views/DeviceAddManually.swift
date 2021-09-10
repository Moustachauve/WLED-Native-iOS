
import SwiftUI

struct DeviceAddManually: View {
    
    @Binding var isVisible: Bool
    
    @State private var address: String = ""
    @State private var customName: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Divider()
                HStack {
                    Text("Address")
                        .fontWeight(.semibold)
                    TextField("IP Address or URL", text: $address)
                }
                .padding(15)
                Divider()
                
                HStack {
                    Text("Custom Name")
                        .fontWeight(.semibold)
                    TextField("(Empty to get from device)", text: $customName)
                }
                .padding(15)
                Divider()
                
                Spacer()
                .navigationTitle("Add Device Manually")
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        isVisible = false
                    } label: {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                    } label: {
                        Text("Add")
                    }
                }
            }
        }
    }
}

struct DeviceAddManually_Previews: PreviewProvider {
    static var previews: some View {
        DeviceAddManually(isVisible: .constant(true))
    }
}
