
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    var webView: WKWebView = WKWebView()
    var url: URL?
    
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
