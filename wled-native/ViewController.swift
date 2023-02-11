import UIKit

class ViewController: UIViewController {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    
    var refreshTimer: Timer?

    var devices = [Device]()
    let deviceApi = DeviceApi()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "My Devices"
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        
        tableView.refreshControl = refreshControl
        tableView.delegate = self
        tableView.dataSource = self
        
        
        if !UserDefaults().bool(forKey: "setup") {
            UserDefaults().set(true, forKey: "setup")
            UserDefaults().set(0, forKey: "count")
        }
        // Get all devices
        loadDevices()
        updateDevices()
        
        refreshTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
    }
    
    @objc func refresh(_ sender: AnyObject) {
        print("refreshing...")
        loadDevices()
        updateDevices()
        refreshControl.endRefreshing()
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
        cell.powerStatus?.onTintColor = uiColorFromHex(rgbValue: Int(device.color))
        cell.powerStatus?.tag = indexPath.row
        cell.powerStatus?.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
        
        cell.brightnessSlider?.value = Float(device.brightness)
        cell.brightnessSlider?.tintColor = uiColorFromHex(rgbValue: Int(device.color))
        cell.brightnessSlider?.maximumTrackTintColor = uiColorFromHex(rgbValue: Int(device.color), alpha: 0.3)
        cell.brightnessSlider?.tag = indexPath.row
        cell.brightnessSlider?.addTarget(self, action: #selector(self.brightnessChanged(_:)), for: .valueChanged)
        
        
        return cell
    }
    
    @objc func switchChanged(_ sender : UISwitch!) {
        let device = devices[sender.tag]
        print("table row switch Changed \(sender.tag):\(device.address)")
        print("The switch is \(sender.isOn ? "ON" : "OFF")")
        
        let postParam = JsonPost(isOn: sender.isOn)
        print(postParam)
        deviceApi.postJson(device: device, jsonData: postParam) { Device in
            DispatchQueue.main.async {
                self.saveDevices()
            }
        }
    }
    
    
    @objc func brightnessChanged(_ sender : UISlider!) {
        let device = devices[sender.tag]
        print("table row brightness Changed \(sender.tag):\(device.address)")
        print("The switch is \(sender.value)")
        
        let postParam = JsonPost(brightness: Int64(sender.value))
        print(postParam)
        deviceApi.postJson(device: device, jsonData: postParam) { Device in
            DispatchQueue.main.async {
                self.saveDevices()
            }
        }
    }
    
    func uiColorFromHex(rgbValue: Int, alpha: Double? = 1.0) -> UIColor {
        
        // &  binary AND operator to zero out other color values
        // >>  bitwise right shift operator
        // Divide by 0xFF because UIColor takes CGFloats between 0.0 and 1.0
        
        let red =   CGFloat((rgbValue & 0xFF0000) >> 16) / 0xFF
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 0xFF
        let blue =  CGFloat(rgbValue & 0x0000FF) / 0xFF
        let alpha = CGFloat(alpha ?? 1.0)
        
        return fixColor(color: UIColor(red: red, green: green, blue: blue, alpha: alpha))
    }
    
    // Fixes the color if it is too dark or too bright depending of the dark/light theme
    func fixColor(color: UIColor) -> UIColor {
        var h = CGFloat(0), s = CGFloat(0), b = CGFloat(0), a = CGFloat(0)
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        b = traitCollection.userInterfaceStyle == .dark ? fmax(b, 0.2) : fmin(b, 0.75)
        return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
    }
}
