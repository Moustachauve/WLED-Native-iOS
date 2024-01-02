
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    var webView: WKWebView = WKWebView()
    var url: URL?
    private let downloadCompleted: (URL) -> ()
    
    init(url: URL?, downloadCompleted: @escaping(URL) -> ()) {
        self.url = url
        self.downloadCompleted = downloadCompleted
    }
    
    func makeUIView(context: Context) -> WKWebView {
        print("WebView makeUIView")
        guard let url = url else {
            return webView
        }
        
        let request = URLRequest(url: url)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        print("WebView updateUIView")
        webView.underPageBackgroundColor = .systemBackground
    }
    
    func onDownloadCompleted(_ filePathDestination: URL) {
        downloadCompleted(filePathDestination)
    }
    
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKDownloadDelegate {
        var parent: WebView
        private var filePathDestination: URL?
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let langStr = {
                switch Locale.current.languageCode {
                case "fr":
                    return "fr"
                default:
                    return "en"
                }
            }()
            
            let htmlPath = Bundle.main.path(forResource: "errorPage.\(langStr)", ofType: "html")
            let htmlUrl = URL(fileURLWithPath: htmlPath!, isDirectory: false)
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
            if navigationAction.shouldPerformDownload {
                decisionHandler(.download, preferences)
            } else {
                decisionHandler(.allow, preferences)
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if navigationResponse.canShowMIMEType {
                decisionHandler(.allow)
            } else {
                decisionHandler(.download)
            }
        }
        
        func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
            filePathDestination = getDownloadPath(suggestedFilename as NSString)
            completionHandler(filePathDestination)
        }
        
        func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
            download.delegate = self
        }
        
        func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
            download.delegate = self
        }
        
        func download(didFailWithError: Error, resumeData: Data?) {
            print("Failed to download: \(didFailWithError)")
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
            return nil
        }
        
        func downloadDidFinish(_ download: WKDownload) {
            guard let filePathDestination = filePathDestination else {
                return
            }
            parent.onDownloadCompleted(filePathDestination)
            cleanUp()
        }
        
        private func getDownloadPath(_ suggestedFilename: NSString, _ counter: Int = 0) -> URL? {
            do {
                guard let downloadDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    print("no document path")
                    return nil
                }
                try FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true)
                
                // Add "(x)" in case the file already exists
                let pathExtension = suggestedFilename.pathExtension
                let pathPrefix = suggestedFilename.deletingPathExtension
                let counterSuffix = counter > 0 ? "(\(counter))" : ""
                let fileName = "\(pathPrefix)\(counterSuffix).\(pathExtension)"
                
                let path = downloadDirectory.appendingPathComponent(fileName)
                if (FileManager.default.fileExists(atPath: path.path)) {
                    return getDownloadPath(suggestedFilename, counter + 1)
                }
                
                return path
            } catch {
                print(error)
                return nil
            }
        }
        
        private func cleanUp() {
            filePathDestination = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
