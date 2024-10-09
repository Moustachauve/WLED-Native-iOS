import Foundation
import Combine
import CoreData

final class WLEDJsonApiHandler: WLEDRequestHandler {
    
    let device: Device
    let urlSession: URLSession = {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 8
        sessionConfig.timeoutIntervalForResource = 18
        sessionConfig.waitsForConnectivity = true
        sessionConfig.httpMaximumConnectionsPerHost = 1
        return URLSession(configuration: sessionConfig)
    }()
    
    init(device: Device) {
        self.device = device
    }
    
    func processRequest(_ request: WLEDRequest) async {
        switch request {
        case let refreshRequest as WLEDRefreshRequest:
            await processRefreshRequest(refreshRequest)
        case let changeStateRequest as WLEDChangeStateRequest:
            await processChangeStateRequest(changeStateRequest)
        case let softwareUpdateRequest as WLEDSoftwareUpdateRequest:
            await processSoftwareUpdateRequest(softwareUpdateRequest)
        default:
            fatalError("Not Implemented")
        }
    }
    
    func processRefreshRequest(_ request: WLEDRefreshRequest) async {
        let url = getJsonApiUrl(path: "json/si")
        guard let url else {
            print("Can't update device, url nil")
            return
        }
        print("Reading api at: \(url)")
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid httpResponse in update")
                self.updateDeviceOnError()
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response in update, unexpected status code: \(httpResponse)")
                self.updateDeviceOnError()
                return
            }
            
            await self.onResultFetchDataSuccess(data: data)
        } catch {
            print("Error with fetching device: \(error)")
            self.updateDeviceOnError()
            return
        }
    }
    
    func processChangeStateRequest(_ request: WLEDChangeStateRequest) async {
        let url = getJsonApiUrl(path: "json/state")
        guard let url else {
            print("Can't post to device, url nil")
            self.updateDeviceOnError()
            return
        }
        print("Posting api at: \(url)")
        do {
            let jsonData = try JSONEncoder().encode(request.state)
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "post"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = jsonData
            
            do {
                let (data, response) = try await urlSession.data(for: urlRequest)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid httpResponse in post")
                    self.updateDeviceOnError()
                    return
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("Error with the response in post, unexpected status code: \(httpResponse)")
                    self.updateDeviceOnError()
                    return
                }
                
                self.onSuccessPostJson(data: data)
            } catch {
                print("Error with fetching device after post: \(error)")
                self.updateDeviceOnError()
                return
            }
        } catch {
            print(error)
            self.updateDeviceOnError()
        }
    }
    
    func processSoftwareUpdateRequest(_ request: WLEDSoftwareUpdateRequest) async {
        let url = getJsonApiUrl(path: "update")
        guard let url else {
            print("Can't upload update to device, url nil")
            return
        }
        print("Uploading update to: \(url)")
        
        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "post"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                    
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"update\"; filename=\"wled.bin\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        do {
            try body.append(Data(contentsOf: request.binaryFile))
        } catch {
            print("Error with reading binary file: \(error)")
            self.updateDeviceOnError()
            return
        }
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        do {
            // Uses shared session to have longer timeouts
            let (data, response) = try await URLSession.shared.upload(for: urlRequest, from: body)
            print("Update response: \(response)")
            print("Update data: \(String(decoding: data, as: UTF8.self))")
            
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid httpResponse in post for update install")
                await request.onFailure()
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response in update install, unexpected status code: \(httpResponse)")
                await request.onFailure()
                return
            }
            
            await request.onCompletion()
        } catch {
            print("Error with installing device update: \(error)")
            await request.onFailure()
            return
        }
    }

    
    private func updateDeviceOnError() {
        
        print("Device \(device.address ?? "unknown") could not be updated. Marking as offline.")
        guard let context = device.managedObjectContext else {
            return
        }
        
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
    
    private func getJsonApiUrl(path: String) -> URL? {
        let urlString = "http://\(device.address ?? "127.0.0.1")/\(path)"
        print(urlString)
        return URL(string: urlString)
    }
    
    @MainActor
    private func onResultFetchDataSuccess(data: Data?) {
        guard let context = device.managedObjectContext else {
            return
        }
        guard let data else {
            return
        }
        
        context.performAndWait {
            do {
                let deviceStateInfo = try JSONDecoder().decode(DeviceStateInfo.self, from: data)
                print("Updating \(deviceStateInfo.info.name)")
                
                if (device.branchValue == Branch.unknown) {
                    device.branchValue = (deviceStateInfo.info.version ?? "").contains("-b") ? Branch.beta : Branch.stable
                }
                
                let deviceVersion = deviceStateInfo.info.version ?? ""
                let releaseService = ReleaseService(context: context)
                let latestUpdateVersionTagAvailable = releaseService.getNewerReleaseTag(
                    versionName: deviceVersion,
                    branch: device.branchValue,
                    ignoreVersion: device.skipUpdateTag ?? ""
                )

                device.setStateValues(state: deviceStateInfo.state)
                device.macAddress = deviceStateInfo.info.mac
                device.name = device.isCustomName ? device.name : deviceStateInfo.info.name
                device.isPoweredOn = deviceStateInfo.state.isOn
                device.networkRssi = deviceStateInfo.info.wifi.rssi ?? 0
                // TODO: Check for isEthernet
                device.isEthernet = false
                device.platformName = deviceStateInfo.info.platformName ?? ""
                device.version = deviceStateInfo.info.version ?? ""
                device.latestUpdateVersionTagAvailable = latestUpdateVersionTagAvailable
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
                updateDeviceOnError()
            }
        }
    }
    
    private func onSuccessPostJson(data: Data?) {
        guard let context = device.managedObjectContext else {
            return
        }
        
        guard let data else { return }
        context.performAndWait {
            do {
                let state = try JSONDecoder().decode(WledState.self, from: data)
                print("Updating \(device.name ?? "[unknown]") from post result")
                
                device.setStateValues(state: state)
                
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
                updateDeviceOnError()
            }
        }
    }
}
