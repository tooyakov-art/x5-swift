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
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
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
