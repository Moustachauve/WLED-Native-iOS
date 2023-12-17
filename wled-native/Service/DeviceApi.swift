import Foundation
import CoreData

class DeviceApi {
    static var urlSession: URLSession?
    
    static func getUrlSession() -> URLSession {
        if (urlSession != nil) {
            return urlSession!
        }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 8
        sessionConfig.timeoutIntervalForResource = 18
        sessionConfig.waitsForConnectivity = false
        urlSession = URLSession(configuration: sessionConfig)
        return urlSession!
    }
    
    func updateDevice(device: Device, context: NSManagedObjectContext) async {
        let url = getJsonApiUrl(device: device, path: "json/si")
        guard let url else {
            print("Can't update device, url nil")
            return
        }
        print("Reading api at: \(url)")
        
        do {
            let (data, response) = try await DeviceApi.getUrlSession().data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid httpResponse in update")
                self.updateDeviceOnError(device: device, context: context)
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response in update, unexpected status code: \(httpResponse)")
                self.updateDeviceOnError(device: device, context: context)
                return
            }
            
            self.onResultFetchDataSuccess(device: device, context: context, data: data)
        } catch {
            print("Error with fetching device: \(error)")
            self.updateDeviceOnError(device: device, context: context)
            return
        }
    }
    
    func postJson(device: Device, context: NSManagedObjectContext, jsonData: JsonPost) async {
        let url = getJsonApiUrl(device: device, path: "json/state")
        guard let url else {
            print("Can't post to device, url nil")
            self.updateDeviceOnError(device: device, context: context)
            return
        }
        print("Posting api at: \(url)")
        do {
            let jsonData = try JSONEncoder().encode(jsonData)
            
            var request = URLRequest(url: url)
            request.httpMethod = "post"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            do {
                let (data, response) = try await DeviceApi.getUrlSession().data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid httpResponse in post")
                    self.updateDeviceOnError(device: device, context: context)
                    return
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("Error with the response in post, unexpected status code: \(httpResponse)")
                    self.updateDeviceOnError(device: device, context: context)
                    return
                }
                
                self.onSuccessPostJson(device: device, context: context, data: data)
            } catch {
                print("Error with fetching device after post: \(error)")
                self.updateDeviceOnError(device: device, context: context)
                return
            }
        } catch {
            print(error)
            self.updateDeviceOnError(device: device, context: context)
        }
    }
    
    private func updateDeviceOnError(device: Device, context: NSManagedObjectContext) {
        print("Device \(device.address ?? "unknown") could not be updated. Marking as offline.")
        
        context.performAndWait {
            device.isOnline = false
            device.isPoweredOn = false
            device.isRefreshing = false
            device.brightness = 0
            device.networkRssi = 0
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func getJsonApiUrl(device: Device, path: String) -> URL? {
        let urlString = "http://\(device.address ?? "127.0.0.1")/\(path)"
        print(urlString)
        return URL(string: urlString)
    }
    
    private func onResultFetchDataSuccess(device: Device, context: NSManagedObjectContext, data: Data?) {
        guard let data else { return }
        context.performAndWait {
            do {
                let deviceStateInfo = try JSONDecoder().decode(DeviceStateInfo.self, from: data)
                print("Updating \(deviceStateInfo.info.name)")
                
                var branch = device.branchValue
                if (branch == Branch.unknown) {
                    branch = (deviceStateInfo.info.version ?? "").contains("-b") ? Branch.beta : Branch.stable
                }
                
                setStateValues(device: device, state: deviceStateInfo.state)
                device.macAddress = deviceStateInfo.info.mac
                device.name = device.isCustomName ? device.name : deviceStateInfo.info.name
                device.isPoweredOn = deviceStateInfo.state.isOn
                device.networkRssi = deviceStateInfo.info.wifi.rssi ?? 0
                // TODO: Check for isEthernet
                device.isEthernet = false
                device.platformName = deviceStateInfo.info.platformName ?? ""
                device.version = deviceStateInfo.info.version ?? ""
                // TODO: Check for new versions
                device.newUpdateVersionTagAvailable = ""
                device.branchValue = branch
                device.brand = deviceStateInfo.info.brand ?? ""
                device.productName = deviceStateInfo.info.product ?? ""
                
                do {
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            } catch {
                print(error)
                updateDeviceOnError(device: device, context: context)
            }
        }
    }
    
    private func onSuccessPostJson(device: Device, context: NSManagedObjectContext, data: Data?) {
        guard let data else { return }
        context.performAndWait {
            do {
                let state = try JSONDecoder().decode(WledState.self, from: data)
                print("Updating \(device.name ?? "[unknown]") from post result")
                
                setStateValues(device: device, state: state)
                
                do {
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            } catch {
                print(error)
                updateDeviceOnError(device: device, context: context)
            }
        }
    }
    
    private func setStateValues(device: Device, state: WledState) {
        device.isOnline = true
        device.brightness = state.brightness
        device.isPoweredOn = state.isOn
        device.isRefreshing = false
        device.color = getColor(state: state)
    }
    
    private func getColor(state: WledState) -> Int64 {
        let colorInfo = state.segment?[0].colors?[0]
        let red = Int64(Double(colorInfo![0]) + 0.5)
        let green = Int64(Double(colorInfo![1]) + 0.5)
        let blue = Int64(Double(colorInfo![2]) + 0.5)
        return (red << 16) | (green << 8) | blue
    }
}
