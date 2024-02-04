
import Foundation

class WLEDJsonApiHandler : WLEDRequestHandler {
    let device: Device
    
    init(device: Device) {
        self.device = device
    }
    
    func processRequest(_ request: WLEDRequest) async {
        switch request {
        case let refreshRequest as WLEDRefreshRequest:
            await processRefreshRequest(refreshRequest)
        case let changeStateRequest as WLEDChangeStateRequest:
            await processChangeStateRequest(changeStateRequest)
        default:
            fatalError("Not Implemented")
        }
    }
    
    func processRefreshRequest(_ refreshRequest: WLEDRefreshRequest) async {
        await DeviceApi().updateDevice(device: device, context: refreshRequest.context)
    }
    
    func processChangeStateRequest(_ changeStateRequest: WLEDChangeStateRequest) async {
        await DeviceApi().postJson(device: device, context: changeStateRequest.context, jsonData: changeStateRequest.state)
    }
    
}
