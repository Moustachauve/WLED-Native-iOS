
import Foundation
import Combine
import Network
import SwiftUI

class DiscoveryService: NSObject, Identifiable {
    
    var browser: NWBrowser!
    
    func scan() {
        let viewContext = PersistenceController.shared.container.viewContext
        let bonjourTCP = NWBrowser.Descriptor.bonjour(type: "_wled._tcp" , domain: "local.")
        
        let bonjourParms = NWParameters.init()
        bonjourParms.allowLocalEndpointReuse = true
        bonjourParms.acceptLocalOnly = true
        bonjourParms.allowFastOpen = true
        
        browser = NWBrowser(for: bonjourTCP, using: bonjourParms)
        browser.stateUpdateHandler = {newState in
            switch newState {
            case .failed(let error):
                print("NW Browser: now in Error state: \(error)")
                self.browser.cancel()
            case .ready:
                print("NW Browser: new bonjour discovery - ready")
            case .setup:
                print("NW Browser: in SETUP state")
            default:
                break
            }
        }
        browser.browseResultsChangedHandler = { ( results, changes ) in
            print("NW Browser: Scan results found:")
            for result in results {
                print(result.endpoint.debugDescription)
            }
            let deviceApi = DeviceApi()
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
                                    let newDevice = Device(context: viewContext)
                                    newDevice.name = name
                                    newDevice.address = "\(remoteHost)"
                                    deviceApi.updateDevice(device: newDevice, context: viewContext)
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
        self.browser.start(queue: DispatchQueue.main)
    }
    
}
