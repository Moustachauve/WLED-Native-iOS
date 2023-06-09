import UIKit

class EntryViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var addressField: UITextField!
    @IBOutlet var nameField: UITextField!
    @IBOutlet var isHiddenLabel: UILabel!
    @IBOutlet var isHiddenSwitch: UISwitch!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var update : ((_: Device) -> Void)?
    
    var device : Device?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(saveDevice))
        navigationItem.rightBarButtonItem?.isEnabled = false
        setupTextFields()
    }
    
    func setupTextFields() {
        addressField.delegate = self
        nameField.delegate = self
        
        if (device != nil) {
            setFieldsFromDevice(device: device!)
        }
        
        addressField.addTarget(self,
                               action: #selector(self.textFieldDidChange(_:)),
                               for: UIControl.Event.editingChanged)
        nameField.addTarget(self,
                            action: #selector(self.textFieldDidChange(_:)),
                            for: UIControl.Event.editingChanged)
        
        addressField.layer.borderColor = UIColor.systemRed.cgColor
        nameField.layer.borderColor = addressField.layer.borderColor
        
        let webImage = UIImage(systemName: "link")
        addressField.leftView = getPaddedImageView(webImage!)
        addressField.leftViewMode = UITextField.ViewMode.always
        
        let nameImage = UIImage(systemName: "heart.text.square")
        nameField.leftView =  getPaddedImageView(nameImage!)
        nameField.leftViewMode = UITextField.ViewMode.always
        
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "eye.slash")
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        let myString = NSMutableAttributedString(string: " " + isHiddenLabel.text!)
        attachmentString.append(myString)
        isHiddenLabel.attributedText = attachmentString
    }
    
    func setFieldsFromDevice(device: Device) {
        addressField.text = device.address
        addressField.isEnabled = false
        if (device.isCustomName) {
            nameField.text = device.name
        }
        nameField.becomeFirstResponder()
        isHiddenSwitch.isOn = device.isHidden
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func getPaddedImageView(_ imageView: UIImage) -> UIView {
        let padding = 8.0
        let imageView = UIImageView(image: imageView)
        imageView.tintColor = UIColor.placeholderText
        let outerView = UIView(frame: CGRect(x: 0, y: 0, width: imageView.image!.size.width + padding, height: imageView.image!.size.height) )
        imageView.frame = CGRectMake(padding, 0.0, imageView.image!.size.width, imageView.image!.size.height)
        outerView.addSubview(imageView)
        return outerView
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (navigationItem.rightBarButtonItem!.isEnabled) {
            saveDevice()
        }
        return true
    }
    
    func isAddressValid() -> Bool {
        // TODO: Add validation that the address doesnt return nil when passed to URL(string:)
        return !(addressField?.text?.isEmpty ?? false)
    }
    
    func isNameValid() -> Bool {
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        // TODO: Add error message in the interface
        let addressIsValid = isAddressValid()
        let nameIsValid = isNameValid()
        navigationItem.rightBarButtonItem?.isEnabled = addressIsValid && nameIsValid
        
        addressField.layer.borderWidth = addressIsValid ? 0 : 1
        nameField.layer.borderWidth = nameIsValid ? 0 : 1
    }
    
    @objc func saveDevice() {
        guard let address = addressField.text, isAddressValid() else {
            return
        }
        guard let name = nameField.text, isNameValid() else {
            return
        }
        
        let isEditMode = device != nil
        let device = device ?? Device(context: context)
        if (!isEditMode) {
            device.address = address
            device.isOnline = false
        }
        device.name = name
        device.isCustomName = name != ""
        device.isHidden = isHiddenSwitch.isOn
        
        update?(device)
        navigationController?.popViewController(animated: true)
    }
}
