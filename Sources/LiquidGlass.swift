import SwiftUI

// MARK: - Core Concepts

/// Defines the visual properties of the Liquid Glass effect.
public struct Glass: Equatable {
    enum Variant {
        case regular
        case clear
        case identity
    }
    
    var variant: Variant
    var tintColor: Color?
    var isInteractive: Bool = false
    
    /// Default adaptation to content.
    public static let regular = Glass(variant: .regular)
    
    /// High transparency for media-rich backgrounds.
    public static let clear = Glass(variant: .clear)
    
    /// No effect applied (conditional disable).
    public static let identity = Glass(variant: .identity)
    
    /// Applies a tint color to the glass.
    public func tint(_ color: Color) -> Glass {
        var copy = self
        copy.tintColor = color
        return copy
    }
    
    /// Enables interactive behaviors (scaling, shimmering, touch response).
    public func interactive() -> Glass {
        var copy = self
        copy.isInteractive = true
        return copy
    }
}

// MARK: - View Modifier

struct GlassEffectModifier<S: Shape>: ViewModifier {
    var glass: Glass
    var shape: S
    var isEnabled: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        if !isEnabled || glass.variant == .identity {
            content
        } else {
            content
                .background(
                    ZStack {
                        // 1. The Material Layer (The "Glass" body)
                        let material: Material = (glass.variant == .clear) ? .thinMaterial : .ultraThinMaterial
                        
                        shape
                            .fill(material)
                        
                        // 2. Tint Layer
                        if let tint = glass.tintColor {
                            shape
                                .fill(tint.opacity(glass.variant == .clear ? 0.1 : 0.2))
                        } else {
                            // Default slight white/black tint for "freshness"
                            shape.fill(Color.primary.opacity(0.05))
                        }
                        
                        // 3. Specular Highlight / Border & Lensing simulation
                        // We simulate "light bending" with a subtle gradient stroke and inner shadows
                        shape
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: .white.opacity(0.5), location: 0),
                                        .init(color: .white.opacity(0.1), location: 0.5),
                                        .init(color: .white.opacity(0.0), location: 1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .blendMode(.overlay)
                    }
                    .shadow(
                        color: Color.black.opacity(glass.variant == .clear ? 0.1 : 0.15),
                        radius: glass.isInteractive ? 8 : 12,
                        x: 0,
                        y: glass.isInteractive ? 4 : 8
                    )
                )
                // Interactive Scale Effect
                .scaleEffect(glass.isInteractive && isPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
    }
    
    // Helper to track press state if interactive (simplified for this generic modifier)
    // Note: In a real ButtonStyle, this is handled by configuration.isPressed. 
    // For a generic view, we might need a tap gesture to track state, but that blocks downstream gestures.
    // For now, we assume 'interactive' mostly visually prepares it, or is used in ButtonStyle.
    // To support the "scaling on press" on any View, we'd need a Button wrapper or similar.
    // Here we just define the property for potential usage.
    @State private var isPressed: Bool = false
}

// MARK: - Extensions

public extension View {
    /// Applies the iOS 26 Liquid Glass effect.
    func glassEffect<S: Shape>(
        _ glass: Glass = .regular,
        in shape: S = Capsule(),
        isEnabled: Bool = true
    ) -> some View {
        self.modifier(GlassEffectModifier(glass: glass, shape: shape, isEnabled: isEnabled))
    }
    
    // Overload for default shape (Capsule is common default in doc examples, though doc says "DefaultGlassEffectShape")
    func glassEffect(
        _ glass: Glass = .regular,
        isEnabled: Bool = true
    ) -> some View {
        self.glassEffect(glass, in: Capsule(), isEnabled: isEnabled)
    }
}
