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

    /// Call after a celebratory event. No-ops if we already asked on this version.
    static func requestReviewAfterMilestone() {
        let defaults = UserDefaults.standard
        let lastVersion = defaults.string(forKey: lastPromptedVersionKey)
        guard lastVersion != currentVersion else { return }

        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        // Small delay so the prompt doesn't collide with the unlock animation/haptic.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            AppStore.requestReview(in: scene)
            defaults.set(currentVersion, forKey: lastPromptedVersionKey)
        }
    }
}
