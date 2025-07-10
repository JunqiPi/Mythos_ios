import SwiftUI

extension Color {
    // MARK: - Modern Design System
    
    // Primary Brand Colors (Pink-Dominant Gradient)
    static let brandPink = Color(red: 255/255, green: 182/255, blue: 193/255)      // #ffb6c1 - Primary
    static let brandPurple = Color(red: 186/255, green: 85/255, blue: 211/255)     // #ba55d3 - More pink-purple
    static let brandBlue = Color(red: 147/255, green: 112/255, blue: 219/255)      // #9370db - Softer blue
    
    // Surface Colors
    static let surface = Color(red: 250/255, green: 250/255, blue: 255/255)       // #fafaff - Very light blue tint
    static let surfaceElevated = Color.white.opacity(0.95)                        // Semi-transparent white for gradient overlay
    static let surfaceHover = Color(red: 245/255, green: 247/255, blue: 255/255)  // #f5f7ff
    static let surfaceCard = Color.white.opacity(0.9)                             // Perfect for cards on gradient
    
    // Text Colors (Proper Contrast)
    static let textPrimary = Color(red: 30/255, green: 35/255, blue: 55/255)      // #1e2337 - Dark blue-gray
    static let textSecondary = Color(red: 100/255, green: 108/255, blue: 130/255) // #646c82 - Medium gray
    static let textTertiary = Color(red: 156/255, green: 163/255, blue: 175/255)  // #9ca3af - Light gray
    static let textOnBrand = Color.white                                          // White text on brand colors
    
    // Semantic Colors
    static let success = Color(red: 34/255, green: 197/255, blue: 94/255)        // #22c55e
    static let warning = Color(red: 245/255, green: 158/255, blue: 11/255)       // #f59e0b
    static let error = Color(red: 239/255, green: 68/255, blue: 68/255)          // #ef4444
    
    // Interactive Colors
    static let interactive = Color(red: 59/255, green: 130/255, blue: 246/255)   // #3b82f6
    static let interactiveHover = Color(red: 37/255, green: 99/255, blue: 235/255) // #2563eb
    
    // Border Colors
    static let border = Color(red: 229/255, green: 231/255, blue: 235/255)       // #e5e7eb
    static let borderFocus = Color.brandPink.opacity(0.5)                        // Focus state
    
    // MARK: - Modern Gradients (Pink-Dominant)
    static let gradientBrand = LinearGradient(
        colors: [Color.brandPink, Color.brandPurple, Color.brandBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientSurface = LinearGradient(
        colors: [Color.surface, Color.surfaceElevated],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let gradientSubtle = LinearGradient(
        colors: [Color.brandPink.opacity(0.1), Color.brandPurple.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Legacy gradients (deprecated)
    static let gradientSakura = LinearGradient(
        colors: [Color.brandPink.opacity(0.1), Color.brandPurple.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let gradientMagical = LinearGradient(
        colors: [Color.brandPink, Color.brandPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let gradientDreamy = LinearGradient(
        colors: [Color.brandPink, Color.brandPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let gradientPeach = LinearGradient(
        colors: [Color.brandPink.opacity(0.1), Color.brandPurple.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Background Gradients  
    static let backgroundGradient = LinearGradient(
        colors: [Color.surface, Color.surfaceElevated],
        startPoint: .top,
        endPoint: .bottom
    )
    static let heroBackgroundGradient = LinearGradient(
        colors: [Color.brandPink.opacity(0.1), Color.brandPurple.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardBackgroundGradient = LinearGradient(
        colors: [Color.surfaceElevated, Color.surface],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Legacy colors (deprecated - use new design system above)
    static let kawaiiPink = Color.brandPink
    static let kawaiiPurple = Color.brandPurple
    static let kawaiiBlue = Color.brandBlue
    
    // MARK: - Shadow Colors
    static let shadowLight = Color.textPrimary.opacity(0.05)
    static let shadowMedium = Color.textPrimary.opacity(0.1)
    static let shadowStrong = Color.textPrimary.opacity(0.15)
    static let shadowBrand = Color.brandPink.opacity(0.2)
}

// MARK: - Modern Theme
extension Color {
    struct AppTheme {
        static let primary = Color.brandPink
        static let secondary = Color.brandPurple
        static let accent = Color.brandPink
        static let background = Color.surface
        static let surface = Color.surfaceElevated
        static let textPrimary = Color.textPrimary
        static let textSecondary = Color.textSecondary
        static let border = Color.border
    }
}

// MARK: - Kawaii Gradients for Cards and Buttons
extension LinearGradient {
    // MARK: - Button Gradients
    static let buttonPrimary = LinearGradient(
        colors: [Color.brandPink, Color.brandPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let buttonSecondary = LinearGradient(
        colors: [Color.surface, Color.surfaceHover],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let buttonSuccess = LinearGradient(
        colors: [Color.success, Color.success.opacity(0.8)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Card Gradients
    static let cardBackground = LinearGradient(
        colors: [Color.surfaceElevated, Color.surface],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardHover = LinearGradient(
        colors: [Color.surfaceHover, Color.surface],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Legacy gradient (use cardBackground instead)
    static let kawaiiCard = LinearGradient(
        colors: [Color.surfaceElevated, Color.surface],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
}

// MARK: - Modern View Modifiers
extension View {
    // Button Styles
    func primaryButton() -> some View {
        self
            .foregroundColor(.textOnBrand)
            .font(.system(.body, design: .rounded, weight: .semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(LinearGradient.buttonPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .shadowBrand, radius: 8, x: 0, y: 4)
    }
    
    func secondaryButton() -> some View {
        self
            .foregroundColor(.textPrimary)
            .font(.system(.body, design: .rounded, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    func cardStyle() -> some View {
        self
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    func modernTapScale() -> some View {
        self.scaleEffect(0.98)
            .animation(.easeInOut(duration: 0.1), value: UUID())
    }
    
    // Legacy support
    func kawaiiFloat() -> some View {
        self.modifier(FloatingModifier())
    }
    
    func kawaiiGlow() -> some View {
        self.modifier(GlowModifier())
    }
}

// MARK: - Beautiful Animation Modifiers
struct FloatingModifier: ViewModifier {
    @State private var isFloating = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -8 : 0)
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: isFloating)
            .onAppear {
                isFloating = true
            }
    }
}

struct BouncingModifier: ViewModifier {
    @State private var isBouncing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isBouncing)
            .onAppear {
                isBouncing = true
            }
    }
}

struct SparkleModifier: ViewModifier {
    @State private var sparkleOpacity = 0.0
    @State private var sparkleOffset = CGSize.zero
    
    func body(content: Content) -> some View {
        content
            .overlay(
                HStack(spacing: 15) {
                    Text("✨")
                        .font(.caption)
                        .opacity(sparkleOpacity)
                        .offset(sparkleOffset)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: sparkleOpacity)
                    
                    Text("🌸")
                        .font(.caption2)
                        .opacity(sparkleOpacity * 0.7)
                        .offset(x: sparkleOffset.width * -0.5, y: sparkleOffset.height * 0.5)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5), value: sparkleOpacity)
                    
                    Text("💖")
                        .font(.caption)
                        .opacity(sparkleOpacity * 0.8)
                        .offset(x: sparkleOffset.width * 0.3, y: sparkleOffset.height * -0.3)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(1.0), value: sparkleOpacity)
                }
                .allowsHitTesting(false),
                alignment: .topTrailing
            )
            .onAppear {
                sparkleOpacity = 0.6
                sparkleOffset = CGSize(width: 10, height: -10)
            }
    }
}

struct GlowModifier: ViewModifier {
    @State private var glowIntensity = 0.0
    
    func body(content: Content) -> some View {
        content
            .shadow(color: .brandPink.opacity(glowIntensity), radius: 10, x: 0, y: 0)
            .shadow(color: .brandPurple.opacity(glowIntensity * 0.7), radius: 15, x: 0, y: 0)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowIntensity)
            .onAppear {
                glowIntensity = 0.2
            }
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .opacity(isPulsing ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var shimmerOffset = -300.0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset)
                .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: shimmerOffset)
            )
            .clipped()
            .onAppear {
                shimmerOffset = 300.0
            }
    }
}

// MARK: - Kawaii Loading View
struct KawaiiLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(LinearGradient.buttonPrimary)
                        .frame(width: 12, height: 12)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.brandPurple)
        }
        .onAppear {
            isAnimating = true
        }
    }
}