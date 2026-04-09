import SwiftUI

struct NameEntryScreen: View {
    @Binding var name: String
    let onNext: () -> Void

    @FocusState private var isFocused: Bool
    @State private var moonScale: CGFloat = 0.6
    @State private var moonOpacity: Double = 0
    @State private var titleOffset: CGFloat = 24
    @State private var titleOpacity: Double = 0
    @State private var fieldOffset: CGFloat = 20
    @State private var fieldOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var moonGlow: CGFloat = 0

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: 0) {
                Spacer()

                // Animated moon icon (replaces BrandIcon to avoid duplicate logo)
                ZStack {
                    Circle()
                        .fill(SLTheme.Colors.primary.opacity(0.12))
                        .frame(width: 110, height: 110)
                        .blur(radius: moonGlow)

                    Text("🌙")
                        .font(.system(size: 64))
                        .scaleEffect(moonScale)
                }
                .opacity(moonOpacity)

                Spacer().frame(height: SLTheme.Spacing.xl)

                // Title
                VStack(spacing: SLTheme.Spacing.sm) {
                    Text("What should we call\nyour energized self?")
                        .font(SLTheme.Typography.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("We'll personalize your sleep journey")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer().frame(height: SLTheme.Spacing.xxl)

                // Name field
                TextField("", text: $name, prompt: Text("Your name").foregroundStyle(SLTheme.Colors.textTertiary))
                    .font(SLTheme.Typography.title2)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .focused($isFocused)
                    .padding(.vertical, SLTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                            .fill(SLTheme.Colors.backgroundTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                                    .stroke(
                                        isFocused ? SLTheme.Colors.primary : Color.white.opacity(0.08),
                                        lineWidth: 1.5
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                            )
                    )
                    .onSubmit {
                        if !name.trimmingCharacters(in: .whitespaces).isEmpty { onNext() }
                    }
                    .offset(y: fieldOffset)
                    .opacity(fieldOpacity)

                Spacer()

                SLPrimaryButton("Continue", icon: "arrow.right") {
                    onNext()
                }
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : buttonOpacity)
                .scaleEffect(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.97 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: name.isEmpty)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.6).delay(0.1)) {
                moonScale = 1.0
                moonOpacity = 1
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                moonGlow = 24
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
                titleOffset = 0
                titleOpacity = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.55)) {
                fieldOffset = 0
                fieldOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.7)) {
                buttonOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                isFocused = true
            }
        }
    }
}
