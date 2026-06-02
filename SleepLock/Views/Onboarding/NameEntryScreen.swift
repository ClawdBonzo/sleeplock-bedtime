import SwiftUI

struct NameEntryScreen: View {
    @Binding var name: String
    let onNext: () -> Void

    @FocusState private var isFocused: Bool
    @State private var floatOffset: CGFloat = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [SLTheme.Colors.primary.opacity(0.2), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 20,
                endRadius: 220
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Animated icon
                ZStack {
                    ForEach(0..<3) { i in
                        let ringOpacity = 0.08 - Double(i) * 0.025
                        let ringSize = CGFloat(100 + i * 44)
                        let delay = 0.1 + Double(i) * 0.12
                        Circle()
                            .stroke(SLTheme.Colors.primary.opacity(ringOpacity), lineWidth: 1)
                            .frame(width: ringSize, height: ringSize)
                            .scaleEffect(appeared ? 1 : 0.3)
                            .opacity(appeared ? 1 : 0)
                            .animation(
                                .spring(response: 0.85, dampingFraction: 0.6).delay(delay),
                                value: appeared
                            )
                    }

                    Image(systemName: "moon.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [SLTheme.Colors.primaryLight, SLTheme.Colors.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: SLTheme.Colors.primary.opacity(0.5), radius: 16)
                        .offset(y: floatOffset)
                        .scaleEffect(appeared ? 1 : 0.4)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.05), value: appeared)
                }

                Spacer().frame(height: 36)

                // Title
                VStack(spacing: 10) {
                    Text("What should we call\nyour energized self?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .offset(y: appeared ? 0 : 28)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.35), value: appeared)

                    Text("We'll personalize your sleep journey")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.45), value: appeared)
                }

                Spacer().frame(height: 40)

                // Name field
                TextField("", text: $name, prompt: Text("Your name").foregroundStyle(SLTheme.Colors.textTertiary))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .focused($isFocused)
                    .padding(.vertical, SLTheme.Spacing.md)
                    .padding(.horizontal, SLTheme.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                            .fill(SLTheme.Colors.backgroundTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                                    .stroke(
                                        isFocused ? SLTheme.Colors.primary : SLTheme.Colors.primary.opacity(0.2),
                                        lineWidth: isFocused ? 2 : 1
                                    )
                            )
                    )
                    .shadow(color: isFocused ? SLTheme.Colors.primary.opacity(0.2) : .clear, radius: 12)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                    .onSubmit { if !name.trimmingCharacters(in: .whitespaces).isEmpty { onNext() } }
                    .padding(.horizontal, SLTheme.Spacing.xl)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.55), value: appeared)

                Spacer()

                // CTA
                Button(action: {
                    isFocused = false
                    onNext()
                }) {
                    HStack(spacing: SLTheme.Spacing.sm) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                        Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? "Enter your name" : "Continue as \(name.components(separatedBy: " ").first ?? name)")
                            .font(SLTheme.Typography.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background {
                        if name.trimmingCharacters(in: .whitespaces).isEmpty {
                            Color(hex: "2A2A5A")
                        } else {
                            LinearGradient(
                                colors: [SLTheme.Colors.primary, Color(hex: "8B5CF6")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
                    .shadow(
                        color: name.isEmpty ? .clear : SLTheme.Colors.primary.opacity(0.4),
                        radius: 12, y: 4
                    )
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: name.isEmpty)
                .padding(.horizontal, SLTheme.Spacing.xl)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.7), value: appeared)
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
            .scrollableCentered()
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { isFocused = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatOffset = -8
            }
        }
    }
}
