import SwiftUI
import UIKit

/// Persisted per-app accessibility preferences stored in UserDefaults via @AppStorage.
/// Values default to whatever the system reports on first launch, so users who have
/// already configured iOS accessibility get the right behaviour without any extra steps.
final class AccessibilitySettings: ObservableObject {

    /// Skip or simplify motion-heavy animations (paper airplane fold/throw, transitions).
    /// Defaults to the system "Reduce Motion" value.
    @AppStorage("a11y_reduceMotion")
    var reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled

    /// Suppress UIFeedbackGenerator calls throughout the app.
    @AppStorage("a11y_reduceHaptics")
    var reduceHaptics: Bool = false

    /// Strengthen borders and background fills on cards and inputs for users
    /// with low-vision needs. Defaults to the system "Increase Contrast" value.
    @AppStorage("a11y_increaseContrast")
    var increaseContrast: Bool = UIAccessibility.isDarkerSystemColorsEnabled

    // MARK: - Convenience helpers

    /// Returns true when motion should be suppressed, checking both the in-app
    /// toggle and the live system flag so late changes in Control Centre are respected.
    var motionReduced: Bool {
        reduceMotion || UIAccessibility.isReduceMotionEnabled
    }

    /// Returns true when haptics should be suppressed.
    var hapticsReduced: Bool {
        reduceHaptics
    }

    /// Card border opacity — stronger when high-contrast is on.
    var cardBorderOpacity: Double {
        increaseContrast ? 0.55 : 0.0
    }

    /// Input overlay border — stronger when high-contrast is on.
    var inputBorderOpacity: Double {
        increaseContrast ? 0.6 : 0.3
    }
}
