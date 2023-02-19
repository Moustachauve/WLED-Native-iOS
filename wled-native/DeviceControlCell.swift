import Foundation
import UIKit

class DeviceControlCell: UITableViewCell {
    @IBOutlet var name : UILabel?
    @IBOutlet var address : UILabel?
    @IBOutlet var powerStatus : UISwitch?
    @IBOutlet var brightnessSlider : UISlider?
    @IBOutlet var signalImage : UIImageView?
    @IBOutlet var editImage : UIImageView?
    @IBOutlet var editChevronImage : UIImageView?
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        powerStatus?.isEnabled = !editing
        brightnessSlider?.isEnabled = !editing
        
        if (animated) {
            UIView.animate(
                withDuration: 0.15,
                animations: {
                    self.powerStatus?.alpha = (editing ? 0 : 1)
                    self.brightnessSlider?.alpha = (editing ? 0.2 : 1)
                    self.editImage?.alpha = (editing ? 1 : 0)
                    self.editChevronImage?.alpha = (editing ? 1 : 0)
                },
                completion: { (value: Bool) in
                    //if let complete = onCompletion { complete() }
                }
            )
        } else {
            self.powerStatus?.alpha = (editing ? 0 : 1)
            self.brightnessSlider?.alpha = (editing ? 0 : 1)
            self.editImage?.alpha = (editing ? 1 : 0)
            self.editChevronImage?.alpha = (editing ? 1 : 0)
        }
    }
}
