
import Foundation
import Combine
import CoreData
import Network
import SwiftUI

final class DiscoveryService: NSObject, Identifiable, Sendable {
    
    let browser = {
        let bonjourTCP = NWBrowser.Descriptor.bonjour(type: "_wled._tcp" , domain: "local.")
        
        let bonjourParms = NWParameters.init()
        bonjourParms.allowLocalEndpointReuse = true
        bonjourParms.acceptLocalOnly = true
        bonjourParms.allowFastOpen = true
        
        let browser = NWBrowser(for: bonjourTCP, using: bonjourParms)
        browser.stateUpdateHandler = { @Sendable newState in
            switch newState {
            case .failed(let error):
                print("NW Browser: now in Error state: \(error)")
                browser.cancel()
            case .ready:
                print("NW Browser: new bonjour discovery - ready")
            case .setup:
                print("NW Browser: in SETUP state")
            default:
                break
            }
        }
        browser.browseResultsChangedHandler = { @Sendable ( results, changes ) in
            print("NW Browser: Scan results found:")
            for result in results {
                print(result.endpoint.debugDescription)
            }
            for change in changes {
                if case .added(let added) = change {
                    print("NW Browser: Added")
                    if case .service(let name, _, _, _) = added.endpoint {
                        print("Connecting to \(name)")
                        let connection = NWConnection(to: added.endpoint, using: .tcp)
                        connection.stateUpdateHandler = { state in
                            switch state {
                            case .ready:
                                if let innerEndpoint = connection.currentPath?.remoteEndpoint,
                                   case .hostPort(let host, let port) = innerEndpoint {
                                    let remoteHost = "\(host)".split(separator: "%")[0]
                                    print("Connected to", "\(remoteHost):\(port)")
                                    addDevice(name: name, host: "\(remoteHost)")
                                }
                            default:
                                break
                            }
                        }
                        connection.start(queue: .global())
                    }
                }
            }
        }
        return browser
    }()
    
    func scan() {
        self.browser.start(queue: DispatchQueue.main)
    }
    
    static func addDevice(name: String, host: String) {
        let viewContext = PersistenceController.shared.container.viewContext
        viewContext.performAndWait {
            if (doesDeviceAlreadyExists(host: host, viewContext: viewContext)) {
                return
            }
            // TODO: Add mac address checkup like on Android for ip changes
            let newDevice = Device(context: viewContext)
            newDevice.tag = UUID()
            newDevice.name = name
            newDevice.address = host
            newDevice.isHidden = false
            Task {
                await newDevice.refresh()
            }
        }
    }
    
    static func doesDeviceAlreadyExists(host: String, viewContext: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<Device>
        fetchRequest = Device.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(
            format: "address LIKE %@", host
        )
        
        do {
            let device = try viewContext.fetch(fetchRequest)
            return !device.isEmpty
        } catch {
            print("Unexpected error when checking for device existance in discovery: \(error)")
            return false
        }
    }
}
