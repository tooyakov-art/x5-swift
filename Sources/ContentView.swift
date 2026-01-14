import SwiftUI

struct ContentView: View {
    @StateObject private var navigation = NavigationManager()
    @Environment(\.scenePhase) var scenePhase
    @State private var reloadTrigger = UUID()
    
    var body: some View {
        ZStack {
            // Force white background to cover any safe area gaps
            Color.white.edgesIgnoringSafeArea(.all)

            // Main WebView
            WebView(url: Config.targetURL, reloadTrigger: $reloadTrigger, navigation: navigation)
                .edgesIgnoringSafeArea(.all)
            
            // Native Overlays
            if navigation.showPayment {
                PaymentView(navigation: navigation)
            }
            
            if navigation.showLogin {
               LoginView(navigation: navigation)
            }
            
            if navigation.isLoading {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(100) // Ensure it's always on top
            }
        }
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true) // Optional: Hide status bar for cleaner look
        // .onChange(of: scenePhase) { newPhase in
        //     if newPhase == .active {
        //         print("App is active, triggering reload")
        //         reloadTrigger = UUID()
        //     }
        // }
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
