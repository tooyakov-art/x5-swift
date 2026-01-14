import SwiftUI

// MARK: - Button Styles

public struct GlassButtonStyle: ButtonStyle {
    public enum Variant {
        case glass
        case glassProminent
    }
    
    var variant: Variant
    var borderShape: AnyShape = AnyShape(Capsule()) // Default
    
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.controlSize) var controlSize
    
    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        
        configuration.label
            .font(.body.weight(.medium))
            .padding(paddingForSize(controlSize))
            .background(
                Group {
                    if variant == .glassProminent {
                        // Prominent: Opaque background, often tinted
                        ZStack {
                            if isEnabled {
                                Color.accentColor
                            } else {
                                Color.gray.opacity(0.3)
                            }
                        }
                        .clipShape(Capsule()) // Simplified, really should use shape from env
                    } else {
                        // Glass: Translucent
                        Color.clear
                            .glassEffect(
                                isEnabled ? .regular.interactive() : .identity,
                                in: Capsule() // Placeholder for dynamic shape
                            )
                    }
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
    
    func paddingForSize(_ size: ControlSize) -> EdgeInsets {
        switch size {
        case .mini: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        case .small: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        case .large: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        case .regular: fallthrough
        @unknown default: return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        }
    }
}

// Ensure AnyShape wrapper exists or we use specific shapes. 
// For simplicity in this file, we define a wrapper.
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ wrapped: S) {
        _path = { rect in
            let path = wrapped.path(in: rect)
            return path
        }
    }

    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }
}

// MARK: - Extensions

public extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle {
        GlassButtonStyle(variant: .glass)
    }
    
    static var glassProminent: GlassButtonStyle {
        GlassButtonStyle(variant: .glassProminent)
    }
}

// Note: To support .buttonBorderShape reading, we would need to capture it from the environment 
// inside the style's makeBody. 
// SwiftUI's native .buttonBorderShape is available in iOS 15+. 
// We can try to respect it if we can access it, but it's not easily exposed to custom styles without bridging.
// For this reference implementation, we default to Capsule but allow the user to clip it if needed.
