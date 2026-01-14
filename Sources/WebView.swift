import UIKit
import SwiftUI
import WebKit
import AuthenticationServices

// MARK: - Navigation Manager
class NavigationManager: ObservableObject {
    @Published var showPayment: Bool = false
    @Published var showLogin: Bool = false
    @Published var isLoading: Bool = true 
    weak var webView: WKWebView? 
    
    func sendTabEvent(index: Int) {
        let js = "window.postMessage(JSON.stringify({ type: 'TAB_SELECTED', payload: { index: \(index) } }), '*')"
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(js)
        }
    }
}

// MARK: - WebView wrapper
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var reloadTrigger: UUID
    @ObservedObject var navigation: NavigationManager

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Add script message handler
        // IMPORTANT: Name must be strictly "x5App" per protocol
        config.userContentController.add(context.coordinator, name: "x5App")
        
        // Inject x5Platform = 'ios' at document end
        let js = "window.x5Platform = 'ios';"
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)
        
        let webView = WKWebView(frame: .zero, configuration: config)
        
        // Capture reference for JS evaluation
        DispatchQueue.main.async {
            self.navigation.webView = webView
        }
        webView.navigationDelegate = context.coordinator
        
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        
        config.allowsInlineMediaPlayback = true
        
        // Inject Platform Info via UserAgent
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1 X5IOSClient"
        
        // UI Fixes (White Background, No Black Bars)
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        
        // CRITICAL: Disable safe area insets so content flows under notch/home bar
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // LOAD THE URL!
        webView.load(URLRequest(url: url))
        
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Reload if trigger changed
        if context.coordinator.lastReloadTrigger != reloadTrigger {
            context.coordinator.lastReloadTrigger = reloadTrigger
            print("App returned to foreground: Reloading WebView...")
            webView.reload()
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        var parent: WebView
        var lastReloadTrigger: UUID = UUID()

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
                    
                case "LOGIN_GOOGLE":
                     // Trigger Google Sign-In Flow
                     print("Triggering Google Login...")
                     // TODO: Implement ASWebAuthenticationSession or GIDSignIn
                     // For now, we just acknowledge or show a placeholder.
                     self.handleGoogleLogin()

                case "LOGIN_APPLE":
                     print("Triggering Apple Login...")
                     // TODO: Implement ASAuthorizationAppleIDProvider
                     self.handleAppleLogin()

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
        
        
        func handleAppleLogin() {
            print("Native Apple Login Requested")
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
        
        // MARK: - ASAuthorizationControllerDelegate
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                var nameStr = "Apple User"
                if let given = fullName?.givenName, let family = fullName?.familyName {
                    nameStr = "\(given) \(family)"
                }
                
                // Send to Web
                self.sendAuthSuccess(uid: userIdentifier, email: email ?? "", displayName: nameStr, photoURL: "")
            }
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print("Apple Auth Failed: \(error.localizedDescription)")
            // Optionally send error to web?
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return self.parent.navigation.webView?.window ?? ASPresentationAnchor()
        }
        
        func handleGoogleLogin() {
            // Placeholder for Native Google Sign In
            // In a real implementation with GIDSignIn:
            // GIDSignIn.sharedInstance.signIn(...) { user, error in
            //     if let user = user {
            //         self.sendAuthSuccess(user: user)
            //     }
            // }
            print("Native Google Login Requested")
        }

        // MARK: - Outgoing Events
        
        func sendAuthSuccess(uid: String, email: String, displayName: String, photoURL: String) {
            let payload: [String: Any] = [
                "uid": uid,
                "email": email,
                "displayName": displayName,
                "photoURL": photoURL
            ]
            sendEventToWeb(type: "AUTH_SUCCESS", payload: payload)
        }
        
        func sendTabSelected(index: Int) {
            // Sends TAB_SELECTED event to web so it can navigate
            sendEventToWeb(type: "TAB_SELECTED", payload: ["index": index])
        }
        
        func sendEventToWeb(type: String, payload: [String: Any]) {
            let jsonDict: [String: Any] = [
                "type": type,
                "payload": payload
            ]
            
            if let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: []),
               let jsonString = String(data: data, encoding: .utf8) {
                
                print("Sending Event to Web -> Type: \(type)")
                DispatchQueue.main.async {
                    self.parent.navigation.webView?.evaluateJavaScript("window.postMessage(\(jsonString), '*')")
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
            // DispatchQueue.main.async {
            //    self.parent.navigation.isLoading = true
            // }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                withAnimation {
                    self.parent.navigation.isLoading = false
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
