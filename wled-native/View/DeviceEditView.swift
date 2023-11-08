
import SwiftUI

struct DeviceEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @ObservedObject var device: Device
    
    enum Field {
        case name
    }
    
    @State private var address: String = ""
    @State private var customName: String = ""
    @State private var hideDevice: Bool = false
    @State private var isFormValid: Bool = true
    @FocusState var focusedField: Field?
    
    init(device: Device) {
        self.device = device
        _address = State<String>(initialValue: device.address ?? "")
        _customName = State<String>(initialValue: device.isCustomName ? (device.name ?? "") : "")
        _hideDevice = State<Bool>(initialValue: device.isHidden)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("IP Address or URL")
                TextField("IP Address or URL", text: $address)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
            }
            
            VStack(alignment: .leading) {
                Text("Custom Name")
                TextField("Custom Name", text: $customName)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.send)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(customName.isEmpty || isNameValid() ? Color.clear : Color.red))
                    .onChange(of: customName) { _ in
                        validateForm()
                    }
                    .onSubmit {
                        addItem()
                    }
            }
            Toggle("Hide this Device", isOn: $hideDevice)
            
            
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem {
                Button(action: addItem) {
                    Text("Save")
                }
                .disabled(!isFormValid)
            }
        }
        .navigationTitle("Edit Device")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func validateForm() {
        let nameIsValid = isNameValid()
        // TODO: Make form invalid if nothing changed
        isFormValid = nameIsValid
    }
    
    func isNameValid() -> Bool {
        return true
    }
    
    private func removeProtocol(address: String?) -> String? {
        guard let address else {
            return address
        }
        return address
            .replacingOccurrences(of: "https://", with: "", options: .anchored)
            .replacingOccurrences(of: "http://", with: "", options: .anchored)
    }
    
    private func addItem() {
        guard isFormValid else {
            return
        }
        withAnimation {
            device.name = customName
            device.isCustomName = !customName.isEmpty
            device.isHidden = hideDevice
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct DeviceEditView_Previews: PreviewProvider {
    static var previews: some View {
        
        let device = Device(context: PersistenceController.preview.container.viewContext)
        device.name = "A custom name"
        device.isCustomName = true
        device.address = "192.168.11.101"
        device.isHidden = true
        
        
        return DeviceEditView(device: device)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
