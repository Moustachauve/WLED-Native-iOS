
import Foundation

struct Device: Hashable, Codable {
    var address: String
    var name: String = ""
    var isCustomName: Bool = false
    var isHidden: Bool = false
    
    var brightness: Int = 0
    var color: Int = 0
    var isPoweredOn: Bool = false
    var isOnline: Bool = false
    var isRefreshing: Bool = false
    var networkRssi: Int = -101
    
    enum CodingKeys: String, CodingKey {
        case address, name, isCustomName, isHidden
    }
}
