
import SwiftUI
import CoreData
import MarkdownUI

struct DeviceUpdateDetails: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var device: Device
    
    @State var showWarningDialog = false
    @State var showInstallingDialog = false
    
    var version : Version? {
        let fetchRequest = Version.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tagName == %@", device.latestUpdateVersionTagAvailable ?? "")
        
        
        do {
            return try viewContext.fetch(fetchRequest).first
        } catch {
            print("Unexpected error when loading version: \(error)")
            return nil
        }
        
    }
    
    
    var body: some View {
        VStack {
            ScrollView {
                Markdown(version?.versionDescription ?? "[Unknown Error]")
                    .padding()
            }
        }
        .navigationTitle("Version \(version?.tagName ?? "")")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Skip This Version") {
                    skipVersion()
                }
                
                Spacer()
                
                Button("Install") {
                    showWarningDialog = true
                }
                .buttonStyle(.borderedProminent)
                .confirmationDialog("Are you sure?",
                                    isPresented: $showWarningDialog) {
                    Button("Install Now") {
                        installVersion()
                    }
                } message: {
                    Text("You are about to install a new version of WLED on your device. If you had a custom version installed previously, you might lose some functionalities (for example, if you had some usermods enabled, they might not work anymore). \n\nIf someone installed this device for you, you should maybe ask them if it is alright to update the device to a new version. \n\nWLED and WLED Native are not responsible if something goes wrong due to an update.")
                }
            }
        }
        .fullScreenCover(isPresented: $showInstallingDialog) {
            if let version = version {
                DeviceUpdateInstalling(version: version)
                    .background(BackgroundBlurView())
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteUpdateInstall)) {_ in
            dismiss()
        }
    }
    
    func skipVersion() {
        device.skipUpdateTag = device.latestUpdateVersionTagAvailable
        device.latestUpdateVersionTagAvailable = ""
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        dismiss()
    }
    
    func installVersion() {
        showInstallingDialog = true
    }
    
    
}

struct DeviceUpdateDetails_Previews: PreviewProvider {
    static let device = Device(context: PersistenceController.preview.container.viewContext)
    
    static var previews: some View {
        device.tag = UUID()
        device.version = "0.13.0"
        device.latestUpdateVersionTagAvailable = "v0.14.0"
        
        
        return NavigationView{
            DeviceUpdateDetails()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(device)
        }
    }
}
