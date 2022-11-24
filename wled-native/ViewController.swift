import UIKit

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    var devices = [Device]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "My Devices"
        tableView.delegate = self
        tableView.dataSource = self
        
        if !UserDefaults().bool(forKey: "setup") {
            UserDefaults().set(true, forKey: "setup")
            UserDefaults().set(0, forKey: "count")
        }
        // Get all devices
        updateDevices()
    }
    
    func updateDevices() {
        devices.removeAll()
        
        guard let count = UserDefaults().value(forKey: "count") as? Int else {
            return
        }
        
        for x in 0..<count {
            if let deviceAddress = UserDefaults().value(forKey: "device_\(x)") as? String {
                let device = Device(address: deviceAddress, name: "device_\(x)")
                devices.append(device)
            }
        }
        
        tableView.reloadData()
    }

    @IBAction func didTappAdd() {
        let entryViewController = storyboard?.instantiateViewController(withIdentifier: "entry") as! EntryViewController
        entryViewController.title = "New Device"
        entryViewController.update = {
            DispatchQueue.main.async {
                self.updateDevices()
            }
        }
        navigationController?.pushViewController(entryViewController, animated: true)
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let deviceViewController = storyboard?.instantiateViewController(withIdentifier: "device") as! DeviceViewController
        deviceViewController.title = devices[indexPath.row].name
        deviceViewController.position = indexPath.row
        deviceViewController.device = devices[indexPath.row]
        deviceViewController.update = {
            DispatchQueue.main.async {
                self.updateDevices()
            }
        }
        
        navigationController?.pushViewController(deviceViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}


extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath) as! DeviceControlCell
        
        let device = devices[indexPath.row]
        cell.name?.text = device.name
        cell.address?.text = device.address
        return cell
    }
}
