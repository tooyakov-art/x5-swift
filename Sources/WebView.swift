import SwiftUI
import WebKit

// MARK: - Navigation Manager
class NavigationManager: ObservableObject {
    @Published var showPayment: Bool = false
    @Published var showLogin: Bool = false
    @Published var isLoading: Bool = true // Default to true to show loader initially
}

// MARK: - WebView wrapper
struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var navigation: NavigationManager

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Add script message handler
        config.userContentController.add(context.coordinator, name: "appAction")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        config.preferences.javaScriptEnabled = true
        config.allowsInlineMediaPlayback = true
        
        // UI Fixes (White Background, No Black Bars)
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        // Handle JS messages
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let dict = message.body as? [String: Any],
               let action = dict["action"] as? String {
                
                print("Received JS action: \(action)")
                
                DispatchQueue.main.async {
                    if action == "payment" {
                        self.parent.navigation.showPayment = true
                    } else if action == "login" {
                        self.parent.navigation.showLogin = true
                    }
                }
            }
        }
        
        // MARK: - WKNavigationDelegate
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.navigation.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                // Add a small delay to ensure rendering is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.parent.navigation.isLoading = false
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
             DispatchQueue.main.async {
                 self.parent.navigation.isLoading = false
             }
        }
    }
}
