import SwiftUI

struct NameEntryScreen: View {
    @Binding var name: String
    let onNext: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: SLTheme.Spacing.xxl) {
                Spacer()

                VStack(spacing: SLTheme.Spacing.md) {
                    Image("BrandIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: SLTheme.Colors.primary.opacity(0.4), radius: 16)

                    Text("What should we call\nyour energized self?")
                        .font(SLTheme.Typography.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("We'll personalize your sleep journey")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                VStack(spacing: SLTheme.Spacing.sm) {
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
                                )
                        )
                        .onSubmit {
                            if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                                onNext()
                            }
                        }
                }

                Spacer()

                SLPrimaryButton("Continue", icon: "arrow.right") {
                    onNext()
                }
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
    }
}
