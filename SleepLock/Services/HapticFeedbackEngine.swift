import UIKit

@MainActor
final class HapticFeedbackEngine {
    static let shared = HapticFeedbackEngine()

    private init() {}

    // MARK: - Haptic Patterns

    func triggerLevelUp() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            try? await Task.sleep(for: .seconds(0.1))
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            try? await Task.sleep(for: .seconds(0.1))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func triggerQuestCompletion() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.15))
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            try? await Task.sleep(for: .seconds(0.15))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func triggerBadgeUnlock() {
        let patterns: [UIImpactFeedbackGenerator.FeedbackStyle] = [.light, .medium, .light, .heavy]
        Task { @MainActor in
            for style in patterns {
                UIImpactFeedbackGenerator(style: style).impactOccurred()
                try? await Task.sleep(for: .seconds(0.08))
            }
            try? await Task.sleep(for: .seconds(0.08))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func triggerStreakMilestone() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            try? await Task.sleep(for: .seconds(0.15))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func triggerLightTap() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
