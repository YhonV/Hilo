import SwiftUI

struct ReadingCoverBackground: View {
    let coverURL: String?
    @State private var colors: [Color]

    init(coverURL: String?) {
        self.coverURL = coverURL
        _colors = State(initialValue: CoverPalette.cachedColors(for: coverURL) ?? [AppColors.primaryStrong])
    }

    var body: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            // Keep white text legible even with predominantly white covers.
            .overlay(Color.black.opacity(0.62))
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.12)],
                               startPoint: .top, endPoint: .bottom)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task(id: coverURL) {
                guard let coverURL, !coverURL.isEmpty else {
                    colors = [AppColors.primaryStrong]
                    return
                }
                let palette = await CoverPalette.colors(for: coverURL)
                guard !Task.isCancelled else { return }
                colors = palette
            }
    }
}
