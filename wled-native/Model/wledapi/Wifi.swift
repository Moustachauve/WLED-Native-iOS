//
//  DeviceStateInfo.swift
//  wled-native
//
//  Created by Christophe Perso on 2022-12-04.
//

import Foundation

struct Wifi: Decodable {
    var bssid : String?
    var rssi : Int64?
    var signal : Int64?
    var channel : Int64?
    
    
    enum CodingKeys: String, CodingKey {
        case bssid
        case rssi
        case signal
        case channel
    }
}
