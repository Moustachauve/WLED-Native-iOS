//
//  DeviceIdentifier.swift
//  wled-native-macOS
//
//  Created by Robert Brune on 01.12.23.
//

import Foundation


struct DeviceIdentifier: Codable, Hashable {
    let domain: String
    let name: String
    
    var address: String {
        var d = domain
        d.removeLast()
        return name + "." + d
    }
}
