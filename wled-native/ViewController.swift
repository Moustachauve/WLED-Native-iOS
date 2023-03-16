import UIKit

class ViewController: UIViewController {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    
    var refreshTimer: Timer?

    var showHiddenDevices = false
    
    var devices = [Device]()
    let deviceApi = DeviceApi()
    
    let serviceBrowser = NetServiceBrowser()
    var services = [NetService]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLogoInTitle()
        setMenu()
        
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
        refresh(self)
        startTimer()
        
        services.removeAll()
        serviceBrowser.delegate = self
        serviceBrowser.searchForServices(ofType: "_wled._tcp.", inDomain: "")
    }
    
    func setLogoInTitle() {
        let logo = UIImage(named: "wled_logo_akemi")
        let logoImageView = UIImageView(image: logo)
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 165, height: (navigationController?.navigationBar.frame.size.height)!))
        logoImageView.frame = titleView.bounds
        logoImageView.contentMode = .scaleAspectFit
        
        titleView.addSubview(logoImageView)


        navigationItem.titleView = titleView
    }
    
    func setMenu() {
        let barButtonMenu = UIMenu(title: "", children: [
            UIAction(title: NSLocalizedString("Add New Device", comment: ""), image: UIImage(systemName: "plus"), handler: menuAddDevice),
            UIAction(title: NSLocalizedString("Show Hidden Devices", comment: ""), image: UIImage(systemName: "eye"), state: (showHiddenDevices ? .on : .off), handler: toggleShowHidden),
            UIAction(title: NSLocalizedString("Refresh", comment: ""), image: UIImage(systemName: "arrow.clockwise"), handler: menuRefresh),
            UIAction(title: NSLocalizedString("Manage Devices", comment: ""), image: UIImage(systemName: "square.and.pencil"), handler: menuManageDevices)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: barButtonMenu)
    }
    
    @objc func refresh(_ sender: AnyObject) {
        print("refreshing...")
        loadDevices()
        updateDevices()
        refreshControl.endRefreshing()
    }
    
    func menuAddDevice(_ sender: AnyObject) {
        let entryViewController = storyboard?.instantiateViewController(withIdentifier: "entry") as! EntryViewController
        entryViewController.title = NSLocalizedString("New Device", comment: "")
        entryViewController.update = { (device: Device) -> Void in
            self.saveDevices()
        }
        navigationController?.pushViewController(entryViewController, animated: true)
    }
    
    func toggleShowHidden(_ sender: AnyObject) {
        showHiddenDevices = !showHiddenDevices
        setMenu()
        refresh(self)
    }
    
    func menuRefresh(_ sender: AnyObject) {
        refresh(sender)
    }
    
    func menuManageDevices(_ sender: AnyObject) {
        tableView.setEditing(true, animated: true)
        stopTimer()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(menuDoneManageDevice))
    }
    
    @objc func menuDoneManageDevice(_ sender: AnyObject) {
        tableView.setEditing(false, animated: true)
        setMenu()
        startTimer()
        refresh(self)
    }
    
    func loadDevices() {
        // TODO: Display message when no devices in the list
        do {
            let request = Device.fetchRequest()
            if (!showHiddenDevices) {
                request.predicate = NSPredicate(format: "isHidden == %@ || isHidden == nil", NSNumber(value: showHiddenDevices))
            }
            request.sortDescriptors = [
                NSSortDescriptor(key: #keyPath(Device.isOnline), ascending: false),
                NSSortDescriptor(key: #keyPath(Device.name), ascending: true),
                NSSortDescriptor(key: #keyPath(Device.address), ascending: true),
            ]
            devices = try context.fetch(request)
            if (!tableView.isEditing) {
                tableView.reloadData()
            }
            return
        } catch {
            print(error)
        }
    }
    
    func updateDevices() {
        for device in devices {
            if (device.address == nil) {
                return
            }
            // TODO: merge diff to prevent reloading the whole thing
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
    
    func startTimer() {
        refreshTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func openEditDevice(device: Device) {
        let entryViewController = storyboard?.instantiateViewController(withIdentifier: "entry") as! EntryViewController
        entryViewController.title = NSLocalizedString("Edit Device", comment: "")
        entryViewController.device = device
        entryViewController.update = { (device: Device) -> Void in
            self.saveDevices()
        }
        navigationController?.pushViewController(entryViewController, animated: true)
    }
}

extension ViewController: NetServiceBrowserDelegate, NetServiceDelegate {
    func updateInterface () {
        for service in self.services {
            if service.port == -1 {
                service.delegate = self
                service.resolve(withTimeout:10)
            }
        }
    }
    
    @objc func netServiceBrowser(_ serviceBrowser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Detecting a device")
        self.services.append(service)
        if (!moreComing) {
            updateInterface()
        }
    }
    
    @objc func netServiceDidResolveAddress(_ sender: NetService) {
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        guard let data = sender.addresses?.first else { return }
        data.withUnsafeBytes { ptr in
            guard let sockaddr_ptr = ptr.baseAddress?.assumingMemoryBound(to: sockaddr.self) else {
                // handle error
                return
            }
            let sockaddr = sockaddr_ptr.pointee
            guard getnameinfo(sockaddr_ptr, socklen_t(sockaddr.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
                return
            }
        }
        let ipAddress = String(cString:hostname)
        
        // TODO: Maybe not loop over the whole thing, using hashtable? idk
        for device in devices {
            if (device.address == ipAddress) {
                // We already have a device with the same IP
                print("re-discovered " + ipAddress + ", abort")
                return
            }
        }
        
        print("discovered " + ipAddress)
        let device = Device(context: context)
        device.address = ipAddress
        device.name = sender.name
        saveDevices()
        updateDevices()
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let device = devices[indexPath.row]
        
        if (tableView.isEditing) {
            openEditDevice(device: device)
        } else {
            let deviceViewController = storyboard?.instantiateViewController(withIdentifier: "device") as! DeviceViewController
            deviceViewController.title = device.name
            deviceViewController.position = indexPath.row
            deviceViewController.device = device
            navigationController?.pushViewController(deviceViewController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            print("delete button clicked at \(indexPath.section)\\\(indexPath.row)")
            self.context.delete(devices[indexPath.row])
            self.saveDevices()
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            print("insert button clicked at \(indexPath.section)\\\(indexPath.row)")
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        print("trailingSwipeActionsConfigurationForRowAt called, is Editing \(tableView.isEditing)")
        stopTimer()
            
        let add = UIContextualAction(style: .normal, title: NSLocalizedString("Edit", comment: "")) { (action, view, completion ) in
            print("edit called, table is Editing \(tableView.isEditing)")
            self.openEditDevice(device: self.devices[indexPath.row])
            completion(true)
        }
        add.backgroundColor = UIColor.link
        
        let delete = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (action, view, completion ) in
            print("delete called, table is Editing \(tableView.isEditing)")
            self.context.delete(self.devices[indexPath.row])
            self.saveDevices()
            self.tableView.deleteRows(at: [indexPath], with: .none)
            completion(true)
        }
        let config = UISwipeActionsConfiguration(actions: [delete, add])
        return config
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        print("didEndEditingRowAt called, is finished editing \(tableView.isEditing)")
        startTimer()
        refresh(self)
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
        var deviceName = (device.name?.isEmpty ?? false) ? NSLocalizedString("(New Device)", comment: "") : device.name
        if (device.isHidden) {
            deviceName! += NSLocalizedString(" [HIDDEN]", comment: "")
        }
        
        cell.name?.text = deviceName
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
        
        cell.signalImage?.image = UIImage(systemName: getSignalImage(signalStrength: Int(device.networkRssi)), variableValue: getSignalValue(signalStrength: Int(device.networkRssi)))
        
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
    
    func getSignalImage(signalStrength: Int) -> String {
        if (signalStrength == 0) {
            return "wifi.slash"
        }
        return "wifi"
    }
    
    func getSignalValue(signalStrength: Int) -> Double {
        if (signalStrength >= -70) {
            return 1
        }
        if (signalStrength >= -85) {
            return 0.64
        }
        if (signalStrength >= -100) {
            return 0.33
        }
        return 0
    }
}
