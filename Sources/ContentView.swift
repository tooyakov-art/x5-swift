import SwiftUI

struct ContentView: View {
    @StateObject private var navigation = NavigationManager()
    @Environment(\.scenePhase) var scenePhase
    @State private var reloadTrigger = UUID()
    
    // Tab Selection (Visual only, Logic is in Web)
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            // CONTENT: Always the WebView
            WebView(url: Config.targetURL, reloadTrigger: $reloadTrigger, navigation: navigation)
                .edgesIgnoringSafeArea(.all)
                .padding(.bottom, 0) // Web handles its own padding if needed, or we overlap
            
            // CUSTOM LIQUID GLASS TAB BAR
            VStack {
                Spacer()
                
                ZStack {
                    // 1. GLOW (СВЕЧЕНИЕ) — Обязательно для стекла!
                    // Без этого "жидкость" будет выглядеть как грязь
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.6),
                            Color.purple.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 150)
                    .mask(Ellipse().scaleEffect(1.5))
                    .blur(radius: 60) // Сильное размытие для мягкого света
                    .offset(y: 40) // Смещаем вниз под кнопки
                    
                    // 2. Жидкий контейнер
                    GlassEffectContainer(spacing: 0) {
                        // Кнопки
                        TabButton(icon: "house.fill", isSelected: selectedTab == 0) {
                            selectedTab = 0
                            navigation.sendTabEvent(index: 0)
                        }
                        TabButton(icon: "magnifyingglass", isSelected: selectedTab == 1) {
                            selectedTab = 1
                            navigation.sendTabEvent(index: 1)
                        }
                        TabButton(icon: "bell.fill", isSelected: selectedTab == 2) {
                            selectedTab = 2
                            navigation.sendTabEvent(index: 2)
                        }
                        TabButton(icon: "person.fill", isSelected: selectedTab == 3) {
                            selectedTab = 3
                            navigation.sendTabEvent(index: 3)
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 24)
                    // Убираем старый .glassEffect, так как теперь он внутри контейнера
                    .padding(.bottom, 34) 
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            
            // Native Overlays
            if navigation.showPayment { PaymentView(navigation: navigation) }
            if navigation.showLogin { LoginView(navigation: navigation) }
            if navigation.isLoading { LoadingView().transition(.opacity).zIndex(100) }
        }
        .statusBar(hidden: true)
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
                .font(.system(size: 24, weight: isSelected ? .black : .regular)) // Bolder if selected
                .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isSelected ? Color.white : Color.clear)
                        .shadow(color: isSelected ? Color.white.opacity(0.4) : .clear, radius: 8, x: 0, y: 0)
                )
                .frame(maxWidth: .infinity)
                .scaleEffect(isSelected ? 1.0 : 0.9)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// Removed DummyGlassView as it is no longer used

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
