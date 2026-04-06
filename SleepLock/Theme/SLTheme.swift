import SwiftUI

enum SLTheme {
    // MARK: - Colors
    enum Colors {
        static let primary = Color(hex: "6C5CE7")
        static let primaryLight = Color(hex: "A29BFE")
        static let secondary = Color(hex: "00CEC9")
        static let accent = Color(hex: "FDCB6E")
        static let warning = Color(hex: "E17055")
        static let success = Color(hex: "00B894")

        static let backgroundPrimary = Color(hex: "0A0A1A")
        static let backgroundSecondary = Color(hex: "141432")
        static let backgroundTertiary = Color(hex: "1E1E4A")
        static let cardBackground = Color(hex: "1A1A3E")

        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "B0B0D0")
        static let textTertiary = Color(hex: "6B6B8D")

        static let streakGold = Color(hex: "FFD700")
        static let energyGreen = Color(hex: "00E676")
        static let sleepBlue = Color(hex: "448AFF")
        static let moonGlow = Color(hex: "C9B1FF")

        static let gradientPrimary = LinearGradient(
            colors: [primary, Color(hex: "8B5CF6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let gradientEnergy = LinearGradient(
            colors: [energyGreen, Color(hex: "69F0AE")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let gradientNight = LinearGradient(
            colors: [Color(hex: "0F0C29"), Color(hex: "302B63"), Color(hex: "24243E")],
            startPoint: .top,
            endPoint: .bottom
        )

        static let gradientSunrise = LinearGradient(
            colors: [Color(hex: "F093FB"), Color(hex: "F5576C"), Color(hex: "FDCB6E")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let gradientCard = LinearGradient(
            colors: [cardBackground, Color(hex: "1E1E50")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let captionBold = Font.system(size: 12, weight: .semibold, design: .rounded)

        static let streakNumber = Font.system(size: 64, weight: .bold, design: .rounded)
        static let energyScore = Font.system(size: 48, weight: .heavy, design: .rounded)
        static let timerDisplay = Font.system(size: 56, weight: .light, design: .monospaced)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let huge: CGFloat = 48
        static let massive: CGFloat = 64
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 100
    }

    // MARK: - Shadows
    enum Shadow {
        static let card = ShadowStyle(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
        static let glow = ShadowStyle(color: Colors.primary.opacity(0.4), radius: 20, x: 0, y: 0)
        static let subtle = ShadowStyle(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
    }

    // MARK: - Animation
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
