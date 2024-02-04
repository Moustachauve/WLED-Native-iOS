
import Foundation

extension Device {
    var requestManager: WLEDRequestManager {
        get {
            return DeviceStateFactory.shared.getStateForDevice(self).getRequestManager(device: self)
        }
    }
}
