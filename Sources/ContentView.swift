import SwiftUI

struct ContentView: View {
    @StateObject private var navigation = NavigationManager()
    @Environment(\.scenePhase) var scenePhase
    @State private var reloadTrigger = UUID()
    
    // Tab Selection
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            // CONTENT LAYER
            Group {
                switch selectedTab {
                case 0:
                    // HOME: WebView
                    ZStack {
                        Color.white.edgesIgnoringSafeArea(.all)
                        WebView(url: Config.targetURL, reloadTrigger: $reloadTrigger, navigation: navigation)
                    }
                    
                case 1:
                    // SEARCH / EXPLORE
                    DummyGlassView(title: "Explore", icon: "magnifyingglass", color: .purple)
                    
                case 2:
                    // NOTIFICATIONS
                    DummyGlassView(title: "Updates", icon: "bell.fill", color: .blue)
                    
                case 3:
                    // PROFILE
                    DummyGlassView(title: "Profile", icon: "person.crop.circle", color: .orange)
                    
                default:
                    Text("Error")
                }
            }
            .edgesIgnoringSafeArea(.all)
            .padding(.bottom, 80) // Space for TabBar
            
            // Native Overlays (kept from before)
            if navigation.showPayment { PaymentView(navigation: navigation) }
            if navigation.showLogin { LoginView(navigation: navigation) }
            if navigation.isLoading { LoadingView().transition(.opacity).zIndex(100) }
            
            // CUSTOM GLASS TAB BAR
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    TabButton(icon: "house.fill", isSelected: selectedTab == 0) { selectedTab = 0 }
                    TabButton(icon: "magnifyingglass", isSelected: selectedTab == 1) { selectedTab = 1 }
                    TabButton(icon: "bell.fill", isSelected: selectedTab == 2) { selectedTab = 2 }
                    TabButton(icon: "person.fill", isSelected: selectedTab == 3) { selectedTab = 3 }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(.ultraThinMaterial)
                .cornerRadius(30)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .edgesIgnoringSafeArea(.bottom) // Allow TabBar to float
        .statusBar(hidden: true)
        // .onChange ... disabled
    }
}

// MARK: - Components

struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .gray.opacity(0.6))
                .frame(maxWidth: .infinity)
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .animation(.spring(), value: isSelected)
        }
    }
}

struct DummyGlassView: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(gradient: Gradient(colors: [color.opacity(0.8), Color.black]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.5), radius: 20)
                
                Text(title)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                LiquidGlassButton(title: "Action Button", icon: "sparkles") {
                    print("Glass Button Tapped")
                }
                .padding(.horizontal, 40)
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
