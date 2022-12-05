import UIKit

class ViewController: UIViewController {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    
    var devices = [Device]()
    let deviceApi = DeviceApi()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "My Devices"
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        
        tableView.addSubview(refreshControl)
        tableView.delegate = self
        tableView.dataSource = self
        
        
        if !UserDefaults().bool(forKey: "setup") {
            UserDefaults().set(true, forKey: "setup")
            UserDefaults().set(0, forKey: "count")
        }
        // Get all devices
        loadDevices()
        updateDevices()
    }
    
    @objc func refresh(_ sender: AnyObject) {
        loadDevices()
        updateDevices()
    }
    
    func loadDevices() {
        do {
            devices = try context.fetch(Device.fetchRequest())
            tableView.reloadData()
            return
        } catch {
            print(error)
        }
    }
    
    func updateDevices() {
        for device in devices {
            deviceApi.updateDevice(device: device, completionHandler: { [weak self] device in
                DispatchQueue.main.async {
                    self!.saveDevices()
                }
            })
        }
    }
    
    func saveDevices(reloadDevices: Bool = true) {
        do {
            try context.save()
            
            if (reloadDevices) {
                loadDevices()
            }
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
        cell.powerStatus?.isOn = device.isPoweredOn
        cell.brightnessSlider?.value = Float(device.brightness)
        return cell
    }
}
