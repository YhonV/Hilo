import UIKit

/// Feedback for deliberate UI actions. Call success only after the mutation succeeds,
/// before dismissing its view. Background refreshes and native controls stay silent.
@MainActor
enum AppHaptics {
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let impactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func selection() {
        guard UIApplication.shared.applicationState == .active else { return }
        selectionGenerator.selectionChanged()
    }

    static func action() {
        guard UIApplication.shared.applicationState == .active else { return }
        impactGenerator.impactOccurred(intensity: 0.65)
    }

    static func success() { notify(.success) }
    static func warning() { notify(.warning) }
    static func error() { notify(.error) }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UIApplication.shared.applicationState == .active else { return }
        notificationGenerator.notificationOccurred(type)
    }
}
