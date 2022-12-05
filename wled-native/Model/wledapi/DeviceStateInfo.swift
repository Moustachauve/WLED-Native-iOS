//
//  DeviceStateInfo.swift
//  wled-native
//
//  Created by Christophe Perso on 2022-12-04.
//

import Foundation

struct DeviceStateInfo: Decodable {
    var state: State
    var info: Info
}
