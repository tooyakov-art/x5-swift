import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // X5 Logo Animation
                HStack(spacing: 5) {
                    Text("X")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(.blue)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(Animation.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: isAnimating)
                    
                    Text("5")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(Animation.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: isAnimating)
                }
                
                // Loading Indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .padding(.top, 20)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(Animation.easeIn.delay(0.5), value: isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
