
import Foundation

actor DeviceManager {
    static let shared = DeviceManager()
    
    private var allDeviceManager: Dictionary<DeviceID, WLEDRequestManager> = [:]
    private var allDevice: Dictionary<DeviceID, Device> = [:]
    
    func getRequestManager(_ device: DeviceID) -> WLEDRequestManager? {
        return self.allDeviceManager[device]
    }
    
    func getDevice(_ device: DeviceID) -> Device? {
        return self.allDevice[device]
    }
}

struct DeviceID:Hashable,@unchecked Sendable {
    let id: String
    let device: Device
    
    init(device: Device) {
        self.device = device
        self.id = device.address ?? "not_available"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
