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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Delete", style: .done, target: self, action: #selector(deleteDevice))
        
        guard let deviceAddress = device?.address else {
            return
        }
        
        let deviceUrl = URL(string: "http://\(deviceAddress)")
        let request = URLRequest(url: deviceUrl!)
        webView.load(request)
        
    }

    @objc func deleteDevice() {
        delete?(device!)
        navigationController?.popViewController(animated: true)
    }
}
