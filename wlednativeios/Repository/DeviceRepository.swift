
import Foundation

class DeviceRepository {
    let devicesKey = "allDevices"
    
    static let instance = DeviceRepository()
    
    typealias DeviceDictionary = [String : DeviceItem]
    var devices = DeviceDictionary()
    
    private init() {
        let preferences = UserDefaults.standard
        if let devicesData = preferences.value(forKey: devicesKey) as? Data, let loadedDevices = try? PropertyListDecoder().decode(DeviceDictionary.self, from: devicesData) {
            devices = loadedDevices
        }
        
        //for i in 1...10 {
        //    let device = DeviceItem(address: "192.168.10.\(i)")
        //    devices[device.address] = device
        //}
        //save()
    }
    
    func get(address: String) -> DeviceItem? {
        return devices[address]
    }
    
    func getAll() -> [DeviceItem] {
        return devices.values.map{ $0 };
    }
    
    func remove(device: DeviceItem) {
        devices.removeValue(forKey: device.address)
    }
    
    func put(device: DeviceItem) {
        let previousDevice = devices[device.address]
        if (previousDevice == nil) {
            devices[device.address] = device
            save()
            // Notify?
            return
        }
        
        //TODO: Check if need to save
        let needToSave = true
        if (needToSave) {
            save()
        }
        
        if (needToSave || false /*!isSame*/) {
            // Notify?
        }
    }
    
    func contains(device: DeviceItem) -> Bool {
        return devices[device.address] != nil;
    }
    
    private func save() {
        //let preferences = UserDefaults.standard
        //preferences.setValue(devices, forKey: devicesKey)
        
        if let encoded = try? PropertyListEncoder().encode(devices) {
            UserDefaults.standard.set(encoded, forKey: devicesKey)
        }
    }
}
