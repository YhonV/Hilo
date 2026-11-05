import SwiftUI

struct EmptyLibraryBooksView: View {
    let status: Status

    private var icon: String {
        switch status {
        case .reading:
            return "book"
        case .toRead:
            return "bookmark"
        case .read:
            return "checkmark.circle"
        }
    }

    private var titleKey: LocalizedStringKey {
        switch status {
        case .reading:
            return "library_empty_reading_title"
        case .toRead:
            return "library_empty_to_read_title"
        case .read:
            return "library_empty_read_title"
        }
    }

    private var descriptionKey: LocalizedStringKey {
        switch status {
        case .reading:
            return "library_empty_reading_description"
        case .toRead:
            return "library_empty_to_read_description"
        case .read:
            return "library_empty_read_description"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppColors.accent)

            Text(titleKey)
                .font(.headline)
                .foregroundStyle(AppColors.titles)
                .multilineTextAlignment(.center)

            Text(descriptionKey)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.border.opacity(0.55), lineWidth: 1)
        }
    }
}
