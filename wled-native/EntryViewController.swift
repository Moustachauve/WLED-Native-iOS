import UIKit

class EntryViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var field: UITextField!
    
    var update : (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        field.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveDevice))
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveDevice()
        return true
    }
    
    @objc func saveDevice() {
        guard let text = field.text, !text.isEmpty else {
            return
        }
        
        guard let count = UserDefaults().value(forKey: "count") as? Int else {
            return
        }
        UserDefaults().set(text, forKey: "device_\(count)")
        let newCount = count + 1
        UserDefaults().set(newCount, forKey: "count")
        
        update?()
        navigationController?.popViewController(animated: true)
    }
}
