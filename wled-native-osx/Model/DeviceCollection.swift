//
//  DeviceManager.swift
//  wled-osx
//
//  Created by Robert Brune on 24.11.23.
//

import Foundation
import Network
import OSLog


class DeviceCollection: ObservableObject {
    @Published var devices:[DeviceActor] = []
    
    var browser: NWBrowser
    
    init() {
        let bonjourTCP = NWBrowser.Descriptor.bonjour(type: "_wled._tcp" , domain: "local")
        
        let bonjourParms = NWParameters.init()
        bonjourParms.allowLocalEndpointReuse = true
        bonjourParms.acceptLocalOnly = true
        bonjourParms.allowFastOpen = true
        
        browser = NWBrowser(for: bonjourTCP, using: bonjourParms)
        
        browser.stateUpdateHandler = {newState in
            switch newState {
            case .failed(let error):
                Logger().error("NW Browser: now in Error state: \(error)")
                self.browser.cancel()
            case .ready:
                Logger().info("NW Browser: new bonjour discovery - ready")
            case .setup:
                Logger().info("NW Browser: in SETUP state")
            case .cancelled:
                Logger().info("NW Browser: canclled")
            case .waiting(_):
                Logger().info("NW Browser: waiting")
            @unknown default:
                Logger().info("NW Browser: unnown status change")
            }
        }
        
        browser.browseResultsChangedHandler = { ( results, changes ) in
            Logger().info("NW Browser: Scan results found:")
            
            for result in results {
                Logger().info("\(result.endpoint.debugDescription))")
            }
            
            for change in changes {
                if case .added(let added) = change {
                    Logger().info("NW Browser: added")
                    
                    if case .service(let name, _, let domain, _) = added.endpoint {
                        DispatchQueue.main.async {
                            let deviceID = DeviceIdentifier(domain: domain, name: name)
                            let actor = DeviceActor(device: deviceID)
                            self.devices.append(actor)
                        }
                    }
                }
                if case .removed(let removed) = change {
                    if case .service(let name, _, let domain, _) = removed.endpoint {
                        DispatchQueue.main.async {
                            Logger().log("Lose connection to \(name) \(domain)")
                        }
                    }
                }
            }
        }
        
        self.browser.start(queue: DispatchQueue.main)
    }
    
    func close() {
        self.browser.cancel()
    }
}
