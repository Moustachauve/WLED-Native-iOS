import Foundation
import UIKit

class DeviceControlCell: UITableViewCell {
    @IBOutlet var name : UILabel?
    @IBOutlet var address : UILabel?
    @IBOutlet var powerStatus : UISwitch?
    @IBOutlet var brightnessSlider : UISlider?
    @IBOutlet var signalImage : UIImageView?
}
