//
//  Device-Actor.swift
//  wled-osx
//
//  Created by Robert Brune on 21.11.23.
//

import Foundation
import CoreData
import OSLog
import Combine
import WledLib

struct DeviceIdentifier: Codable, Hashable {
    let domain: String
    let name: String
    
    var address: String {
        var d = domain
        d.removeLast()
        return name + "." + d
    }
}

extension String: WledHost {
    public var hostname: String {
        return self
    }
}



actor DeviceActor:Identifiable, ObservableObject {
    
    let id:UUID
    
    @MainActor let identifier:DeviceIdentifier
    @MainActor private var webSocketTask: URLSessionWebSocketTask? = nil
    
    @MainActor @Published var ds:Device? = nil
    @MainActor @Published var presets:Presets? = nil
    
    
    @MainActor
    init(device: DeviceIdentifier) {
        self.id = UUID()
        self.identifier = device
        
        createWebSocket()
        fetchPresets()
    }
    
    nonisolated func createWebSocket() {
        DispatchQueue.main.async {
            do {
                self.webSocketTask = try self.address.getWebsocketReceiver(
                    handleData: self.receiveData(stateData:),
                    handleError: self.error(error:)
                )
            } catch {
                Logger().error("\(error.localizedDescription)")
            }
        }
    }
    
    nonisolated func fetchPresets() {
        do {
            try identifier.address.get { data in
                    DispatchQueue.main.async {
                        self.presets = data
                        Logger().log("Presets loaded: \(String(reflecting: data))")
                    }
                }
                handleError: { error in
                    self.error(error: error)
                }
        } catch {
            self.error(error: error)
        }
    }
    
    nonisolated func post(state: State) {
        do {
            try identifier.address.send(data: state) { (message: SuccessMessage) in
                    guard message.success else {
                        self.error(error: DeviceError.invalidUpdate)
                        return
                    }
                    Logger().info("Update successful.")
                }
                handleError: { error in
                    self.error(error: error)
                }
        } catch {
            self.error(error: error)
        }
    }
    
    
    nonisolated func error(error: Error) {
        Logger().error("Device Error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.ds = nil
            self.webSocketTask?.cancel()
            self.createWebSocket()
        }
    }
    
    nonisolated func receiveData(stateData: Device) {
        Logger().debug("Data receive: \(String(reflecting: stateData))")
        DispatchQueue.main.async {
            self.ds = stateData
        }
    }
}

enum DeviceError : Error {
    case invalidUpdate
}
