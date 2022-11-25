import UIKit

class EntryViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var addressField: UITextField!
    @IBOutlet var nameField: UITextField!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var update : ((_: Device) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addressField.delegate = self
        nameField.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveDevice))
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveDevice()
        return true
    }
    
    @objc func saveDevice() {
        guard let address = addressField.text, !address.isEmpty else {
            return
        }
        let name = nameField.text
        
        let device = Device(context: context)
        device.address = address
        device.name = name
        
        update?(device)
        navigationController?.popViewController(animated: true)
    }
}
