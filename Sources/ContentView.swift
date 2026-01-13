import SwiftUI

struct ContentView: View {
    @StateObject private var navigation = NavigationManager()
    
    var body: some View {
        ZStack {
            // Main WebView
            WebView(url: Config.targetURL, navigation: navigation)
                .edgesIgnoringSafeArea(.bottom)
            
            // Native Overlays
            if navigation.showPayment {
                PaymentView(navigation: navigation)
            }
            
            if navigation.showLogin {
               LoginView(navigation: navigation)
            }
        }
    }
}

// Minimal placeholders for native views
struct PaymentView: View {
    @ObservedObject var navigation: NavigationManager
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            VStack {
                Text("Native Payment Screen")
                    .font(.title)
                    .foregroundColor(.white)
                Button("Close / Success") {
                    navigation.showPayment = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}

struct LoginView: View {
    @ObservedObject var navigation: NavigationManager
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack {
                Text("Native Login Screen")
                    .font(.title)
                Button("Login Success") {
                    navigation.showLogin = false
                }
                .padding()
            }
        }
    }
}
