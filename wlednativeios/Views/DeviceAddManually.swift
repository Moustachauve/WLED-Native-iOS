
import SwiftUI

struct DeviceAddManually: View {
    
    @Binding var isVisible: Bool
    
    @State private var address: String = ""
    @State private var customName: String = ""
    @State private var isDeviceHidden: Bool = false
    
    @State private var addressHasError = false
    
    var body: some View {
        NavigationView {
            VStack {
                Divider()
                VStack(alignment: .leading) {
                    HStack {
                        Text("Address")
                            .fontWeight(.semibold)
                            .foregroundColor(addressHasError ? .red : .primary)
                        TextField("IP Address or URL", text: $address)
                    }
                    if (addressHasError) {
                        Text("Please enter an address")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
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
                
                Toggle("Hide Device", isOn: $isDeviceHidden)
                    .font(Font.body.weight(.semibold))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 15)
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
                        addDevice()
                    } label: {
                        Text("Add")
                    }
                }
            }
        }
    }
    
    func addDevice() {
        addressHasError = address == ""
        if (addressHasError) {
            return;
        }
        
        let device = DeviceItem(
            address: address,
            name: customName,
            isHidden: isDeviceHidden
        )
        
        DeviceRepository.instance.put(device: device)
        
        isVisible = false
    }
}

struct DeviceAddManually_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceAddManually(isVisible: .constant(true))
        }
    }
}
