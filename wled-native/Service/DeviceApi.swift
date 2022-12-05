//
//  DeviceApi.swift
//  wled-native
//
//  Created by Christophe Perso on 2022-12-04.
//

import Foundation

class DeviceApi {
    func updateDevice(device: Device, completionHandler: @escaping (Device) -> Void) {
        
        let url = URL(string: "http://" + device.address! + "/json/si")!
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
                
                completionHandler(device)
                
            } catch {
                print(error)
            }
        })
        task.resume()
    }
}
