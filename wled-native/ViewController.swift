import UIKit

class ViewController: UIViewController {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
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
        do {
            devices = try context.fetch(Device.fetchRequest())
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            
        }
    }
    
    func saveDevices() {
        do {
            try context.save()
            updateDevices()
        } catch {
            
        }
    }

    @IBAction func didTappAdd() {
        let entryViewController = storyboard?.instantiateViewController(withIdentifier: "entry") as! EntryViewController
        entryViewController.title = "New Device"
        entryViewController.update = { (device: Device) -> Void in
            self.saveDevices()
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
        deviceViewController.delete = { (device: Device) -> Void in
            self.context.delete(device)
            self.saveDevices()
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
