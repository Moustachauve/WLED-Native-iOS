import Foundation

class DeviceApi {
    func updateDevice(device: Device, completionHandler: @escaping (Device) -> Void) {
        let url = getJsonApiUrl(device: device, path: "json/si")
        print(url)
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if let error = error {
                print("Error with fetching device: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response, unexpected status code: \(response)")
                return
            }
            
            self.onResultFetchDataSuccess(device: device, completionHandler: completionHandler, data: data)
        })
        task.resume()
    }
    
    func postJson(device: Device, jsonData: JsonPost, completionHandler: @escaping (Device) -> Void) {
        let url = getJsonApiUrl(device: device, path: "json")
        do {
            let jsonData = try JSONEncoder().encode(jsonData)
            
            var request = URLRequest(url: url)
            request.httpMethod = "post"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error with fetching device after post: \(error)")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Error with the response, unexpected status code: \(response)")
                    return
                }
                
                self.onResultFetchDataSuccess(device: device, completionHandler: completionHandler, data: data)
            }
            task.resume()
        } catch {
            print(error)
        }
    }
    
    private func getJsonApiUrl(device: Device, path: String) -> URL {
        return URL(string: "http://\(device.address!)/\(path)")!
    }
    
    private func onResultFetchDataSuccess(device: Device, completionHandler: @escaping (Device) -> Void, data: Data?) {
            guard var data = data else { return }
            print("JSON String: \(String(data: data, encoding: .utf8))")
            
            do {
                let deviceStateInfo = try JSONDecoder().decode(DeviceStateInfo.self, from: data)
                print(deviceStateInfo.info.name)
                device.macAddress = deviceStateInfo.info.mac
                device.isOnline = true
                device.name = device.isCustomName ? device.name : deviceStateInfo.info.name
                device.brightness = deviceStateInfo.state.brightness
                device.isPoweredOn = deviceStateInfo.state.isOn
                device.isRefreshing = false
                device.networkRssi = deviceStateInfo.info.wifi.rssi ?? 0
                
                
                let colorInfo = deviceStateInfo.state.segment?[0].colors?[0]
                let red = Int64(Double(colorInfo![0]) + 0.5)
                let green = Int64(Double(colorInfo![1]) + 0.5)
                let blue = Int64(Double(colorInfo![2]) + 0.5)
                device.color = (red << 16) | (green << 8) | blue
                
                completionHandler(device)
                
            } catch {
                print(error)
            }
    }
}
