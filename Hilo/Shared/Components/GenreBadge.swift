import SwiftUI

struct GenreBadge: View {
    let genre: BookGenre
    var onCover = false

    var body: some View {
        Text(genre.localizedName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(onCover ? .white : AppColors.primaryStrong)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(onCover ? Color.white.opacity(0.12) : AppColors.primaryStrong.opacity(0.08), in: Capsule())
            .overlay {
                Capsule().strokeBorder(onCover ? Color.white.opacity(0.20) : AppColors.primaryStrong.opacity(0.18), lineWidth: 1)
            }
    }
}
