import UIKit

final class HapticFeedbackEngine: @unchecked Sendable {
    static let shared = HapticFeedbackEngine()

    private init() {}

    // MARK: - Haptic Patterns

    func triggerLevelUp() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
        }
    }

    func triggerQuestCompletion() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
        }
    }

    func triggerBadgeUnlock() {
        let patterns: [UIImpactFeedbackGenerator.FeedbackStyle] = [.light, .medium, .light, .heavy]

        for (index, style) in patterns.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                let g = UIImpactFeedbackGenerator(style: style)
                g.impactOccurred()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
        }
    }

    func triggerStreakMilestone() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let g = UIImpactFeedbackGenerator(style: .heavy)
            g.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
        }
    }

    func triggerLightTap() {
        let selectionGenerator = UISelectionFeedbackGenerator()
        selectionGenerator.selectionChanged()
    }
}
