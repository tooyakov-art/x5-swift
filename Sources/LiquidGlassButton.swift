import SwiftUI

struct LiquidGlassButton: View {
    var title: String
    var icon: String?
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Glass Effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .background(.ultraThinMaterial) // Native iOS Blur
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
            )
        }
    }
}

// Preview to verify look
struct LiquidGlassButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                LiquidGlassButton(title: "Get Started", icon: "sparkles") {
                    print("Tapped")
                }
            }
            .padding()
        }
    }
}
