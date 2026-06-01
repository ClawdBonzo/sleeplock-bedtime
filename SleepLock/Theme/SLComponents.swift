import SwiftUI

// MARK: - Primary Button
struct SLPrimaryButton: View {
    let title: LocalizedStringKey
    let icon: String?
    let action: () -> Void

    init(_ title: LocalizedStringKey, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: SLTheme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(SLTheme.Typography.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(SLTheme.Colors.gradientPrimary)
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
            .shadow(color: SLTheme.Colors.primary.opacity(0.4), radius: 12, y: 4)
        }
    }
}

// MARK: - Secondary Button
struct SLSecondaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SLTheme.Typography.headline)
                .foregroundStyle(SLTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(SLTheme.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
        }
    }
}

// MARK: - Card
struct SLCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(SLTheme.Spacing.md)
            .background(SLTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: SLTheme.Radius.xl)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

// MARK: - Glowing Card
struct SLGlowCard<Content: View>: View {
    let glowColor: Color
    let content: Content

    init(glowColor: Color = SLTheme.Colors.primary, @ViewBuilder content: () -> Content) {
        self.glowColor = glowColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(SLTheme.Spacing.md)
            .background(SLTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: SLTheme.Radius.xl)
                    .stroke(glowColor.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: glowColor.opacity(0.15), radius: 12, y: 4)
    }
}

// MARK: - Chip / Tag
struct SLChip: View {
    let title: LocalizedStringKey
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(_ title: LocalizedStringKey, icon: String? = nil, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: SLTheme.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                Text(title)
                    .font(SLTheme.Typography.subheadline)
            }
            .foregroundStyle(isSelected ? .white : SLTheme.Colors.textSecondary)
            .padding(.horizontal, SLTheme.Spacing.md)
            .padding(.vertical, SLTheme.Spacing.sm)
            .background(isSelected ? SLTheme.Colors.primary : SLTheme.Colors.backgroundTertiary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? SLTheme.Colors.primary : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

// MARK: - Progress Ring
struct SLProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color

    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 100, color: Color = SLTheme.Colors.primary) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.6), color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Section Header
struct SLSectionHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?

    init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SLTheme.Spacing.xxs) {
            Text(title)
                .font(SLTheme.Typography.title2)
                .foregroundStyle(SLTheme.Colors.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(SLTheme.Typography.subheadline)
                    .foregroundStyle(SLTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Stat Pill
struct SLStatPill: View {
    let icon: String
    let value: String
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: SLTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(SLTheme.Typography.title2)
                .foregroundStyle(SLTheme.Colors.textPrimary)

            Text(label)
                .font(SLTheme.Typography.caption)
                .foregroundStyle(SLTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SLTheme.Spacing.md)
        .background(SLTheme.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
    }
}

// MARK: - Onboarding Page Container
struct SLOnboardingPage<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            SLTheme.Colors.backgroundPrimary.ignoresSafeArea()

            content
                .padding(.horizontal, SLTheme.Spacing.xl)
        }
    }
}

// MARK: - Animated Stars Background
struct StarsBackground: View {
    @State private var twinkle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Pre-computed fractional positions (x: 0–1, y: 0–1, radius: 0.5–3.5)
    private static let starData: [(CGFloat, CGFloat, CGFloat)] = (0..<80).map { i in
        var gen = SeededRandom(seed: UInt64(i * 17 + 3))
        return (gen.next(), gen.next(), gen.next() * 3 + 0.5)
    }

    var body: some View {
        Canvas { context, size in
            for (fx, fy, radius) in Self.starData {
                let x = fx * size.width
                let y = fy * size.height
                let rect = CGRect(x: x - radius / 2, y: y - radius / 2, width: radius, height: radius)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(twinkle ? 0.6 : 0.25))
                )
            }
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                twinkle = true
            }
        }
    }
}

private struct SeededRandom {
    var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33)) / CGFloat(UInt64(1) << 31)
    }
}
