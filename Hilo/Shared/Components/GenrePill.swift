import SwiftUI

/// Shared visual treatment for genre controls in Search and Home.
struct GenrePill: View {
    let genre: BookGenre
    var fillsWidth = false
    var compact = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: genre.icon)
                .foregroundStyle(genre.color)
                .accessibilityHidden(true)
            Text(genre.localizedName)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.primaryStrong)
                .lineLimit(compact ? 2 : 1)
                .minimumScaleFactor(0.8)
            if fillsWidth { Spacer(minLength: 0) }
        }
        .font(compact ? .caption : .subheadline)
        .padding(.horizontal, compact ? 10 : 14)
        .frame(minHeight: compact ? 40 : 48)
        .glassEffect(.regular.tint(genre.color.opacity(0.12)).interactive(), in: .capsule)
    }
}
