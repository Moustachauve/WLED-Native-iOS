
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    var webView: WKWebView = WKWebView()
    var url: URL?
    
    init(url: URL? = nil) {
        self.url = url
    }
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = url else {
            return
        }
        let request = URLRequest(url: url)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.load(request)
    }
    
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let htmlPath = Bundle.main.path(forResource: "errorPage", ofType: "html")
            let htmlUrl = URL(fileURLWithPath: htmlPath!, isDirectory: false)
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
