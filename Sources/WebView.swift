import UIKit
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
        // IMPORTANT: Name must be strictly "x5App" per protocol
        config.userContentController.add(context.coordinator, name: "x5App")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        config.preferences.javaScriptEnabled = true
        config.allowsInlineMediaPlayback = true
        
        // Inject Platform Info via UserAgent
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1 X5IOSClient"
        
        // UI Fixes (White Background, No Black Bars)
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        
        // CRITICAL: Disable safe area insets so content flows under notch/home bar
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
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
            print("Received message: \(message.name), body: \(message.body)")
            
            guard message.name == "x5App" else { return }
            
            // 1. Try to parse message body
            // Protocol says: window.webkit.messageHandlers.x5App.postMessage(JSON_STRING)
            // So we expect a String. BUT in case they send a Dict, we handle that too.
            
            var messageType: String?
            var payload: [String: Any]?
            
            if let jsonString = message.body as? String {
                if let data = jsonString.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    messageType = dict["type"] as? String
                    payload = dict["payload"] as? [String: Any]
                }
            } else if let dict = message.body as? [String: Any] {
                 messageType = dict["type"] as? String
                 payload = dict["payload"] as? [String: Any]
            }
            
            guard let type = messageType else {
                print("Error: Could not parse message type")
                return
            }
            
            print("Processing action: \(type)")
            
            DispatchQueue.main.async {
                switch type {
                case "PAYMENT_REQUEST":
                     // Trigger Payment Flow
                     self.parent.navigation.showPayment = true
                    
                case "HAPTIC":
                    // Trigger Haptic Feedback
                    if let style = payload?["style"] as? String {
                        self.triggerHaptic(style: style)
                    }
                    
                default:
                    print("Unhandled action type: \(type)")
                }
            }
        }
        
        func triggerHaptic(style: String) {
            let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
            switch style {
            case "light": feedbackStyle = .light
            case "medium": feedbackStyle = .medium
            case "heavy": feedbackStyle = .heavy
            default: feedbackStyle = .medium
            }
            let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
            generator.prepare()
            generator.impactOccurred()
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
