import UIKit
import WebKit

class DeviceViewController: UIViewController, WKUIDelegate {

    var webView: WKWebView!
    var delete : ((_: Device) -> Void)?
    var device: Device?
    var position: Int?
    
    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 400), configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let deviceAddress = device?.address else {
            return
        }
        
        let deviceUrl = URL(string: "http://\(deviceAddress)")
        let request = URLRequest(url: deviceUrl!)
        webView.load(request)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Delete", style: .done, target: self, action: #selector(deleteDevice))
    }

    @objc func deleteDevice() {
        guard let count = UserDefaults().value(forKey: "count") as? Int else {
            return
        }
        let newCount = count - 1
        downshiftOtherDevices(startFrom: position!, limit: count)
        
        
        UserDefaults().set(newCount, forKey: "count")
        delete?(device!)
        navigationController?.popViewController(animated: true)
    }
    
    func downshiftOtherDevices(startFrom: Int, limit: Int) {
        if (startFrom == limit) {
            return
        }
        let valToShift = UserDefaults().value(forKey: "device_\(startFrom + 1)")
        UserDefaults().set(valToShift, forKey: "device_\(startFrom)")
        
        downshiftOtherDevices(startFrom: startFrom + 1, limit: limit)
    }
}
