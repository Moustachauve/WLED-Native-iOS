
import SwiftUI

struct DeviceEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var device: Device
    
    @State var showUpdateDialog: Bool = false
    
    enum Field {
        case name
    }
    
    @State private var address: String = ""
    @State private var customName: String = ""
    @State private var hideDevice: Bool = false
    @State private var isFormValid: Bool = true
    @FocusState var isNameFieldFocused: Bool
    
    /*init() {
    }*/
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("IP Address or URL")
                TextField("IP Address or URL", text: $address)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
            }
            
            VStack(alignment: .leading) {
                Text("Custom Name")
                TextField("Custom Name", text: $customName)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: isNameFieldFocused) { isFocused in
                        if (!isFocused) {
                            let wasCustomName = device.isCustomName
                            if (!customName.isEmpty) {
                                device.name = customName
                            } else if (wasCustomName) {
                                // If we used to have a custom name and we no longer have one,
                                // clear the custom name so the normal name can be picked up later
                                device.name = ""
                            }
                            device.isCustomName = !customName.isEmpty
                            saveDevice()
                        }
                    }
            }
            Toggle("Hide this Device", isOn: $hideDevice)
                .onChange(of: hideDevice) { newValue in
                    device.isHidden = newValue
                    saveDevice()
                }
                .padding(.bottom)
            
            VStack(alignment: .leading) {
                if ((device.newUpdateVersionTagAvailable ?? "").isEmpty) {
                    Text("Your device is up to date")
                    Text("Version \(device.version ?? "[unknown]")")
                    Button(action: checkForUpdate) {
                        Text("Check for Update")
                    }
                    .buttonStyle(.bordered)
                } else {
                    HStack {
                        Image(systemName: "arrow.down.circle.dotted")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30.0, height: 30.0)
                            .padding(.trailing)
                        VStack(alignment: .leading) {
                            Text("Update Available")
                            Text("From \(device.version ?? "[unknown]") to \(device.newUpdateVersionTagAvailable ?? "[unknown]")")
                            Button(action: toggleUpdateDialog) {
                                Text("See Update")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Edit Device")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear() {
            address = device.address ?? ""
            customName = device.isCustomName ? (self.device.name ?? "") : ""
            hideDevice = device.isHidden
        }
    }
    
    private func saveDevice() {
        device.isRefreshing = false
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func checkForUpdate() {
        
    }
    
    private func toggleUpdateDialog() {
        showUpdateDialog = !showUpdateDialog
    }
}

struct DeviceEditView_Previews: PreviewProvider {
    static let device = Device(context: PersistenceController.preview.container.viewContext)
    
    static var previews: some View {
        device.tag = UUID()
        device.name = "A custom name"
        device.isCustomName = true
        device.address = "192.168.11.101"
        device.isHidden = true
        device.version = "1.2.3"
        device.newUpdateVersionTagAvailable = "v1.2.4"
        
        
        return DeviceEditView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(device)
    }
}
