//
//  DeviceStateInfo.swift
//  wled-native
//
//  Created by Christophe Perso on 2022-12-04.
//

import Foundation

struct FileSystem: Decodable {
    var spaceUsed : Int64?
    var spaceTotal : Int64?
    var presetLastModification : Int64?
    
    enum CodingKeys: String, CodingKey {
        case spaceUsed = "u"
        case spaceTotal = "t"
        case presetLastModification = "pmt"
    }
}
