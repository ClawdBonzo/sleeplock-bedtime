import Foundation
import StoreKit
import SwiftUI
import UIKit

/// Requests an App Store review at high-satisfaction moments (a milestone badge
/// unlock or a streak milestone). Apple throttles the prompt to ~3×/year, so we
/// also guard locally to ask at most once per app version and only after a
/// genuine "win" — never on a cold launch or mid-task.
@MainActor
enum RatingService {
    private static let lastPromptedVersionKey = "rating.lastPromptedVersion"

    private static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    private static let lastPromptedDateKey = "rating.lastPromptedDate"
    /// Minimum gap between prompts even across versions (Apple caps at 3/yr).
    private static let minDaysBetweenPrompts: TimeInterval = 60 * 60 * 24 * 30

    /// Early "win" moments that happen within a user's first week — the
    /// 7/30-day badges are too late for most users to ever see a prompt.
    static func requestReviewIfEarlyWin(currentStreak: Int, nightsLogged: Int) {
        if currentStreak == 3 || nightsLogged == 5 {
            requestReviewAfterMilestone()
        }
    }

    /// Call after a celebratory event. No-ops if we already asked on this
    /// version or within the last 30 days.
    static func requestReviewAfterMilestone() {
        let defaults = UserDefaults.standard
        let lastVersion = defaults.string(forKey: lastPromptedVersionKey)
        guard lastVersion != currentVersion else { return }
        if let last = defaults.object(forKey: lastPromptedDateKey) as? Date,
           Date().timeIntervalSince(last) < minDaysBetweenPrompts { return }

        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        // Small delay so the prompt doesn't collide with the unlock animation/haptic.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            AppStore.requestReview(in: scene)
            defaults.set(currentVersion, forKey: lastPromptedVersionKey)
            defaults.set(Date(), forKey: lastPromptedDateKey)
        }
    }
}
