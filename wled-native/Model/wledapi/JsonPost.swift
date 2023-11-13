
import Foundation

struct JsonPost: Decodable, Encodable {
    var isOn : Bool?
    var brightness : Int64?
    
    // "v" will make the post request return the current state of the device
    // So we can also update the UI while setting values
    var verbose : Bool = true
    
    enum CodingKeys: String, CodingKey {
        case isOn = "on"
        case brightness = "bri"
        case verbose = "v"
    }
}
