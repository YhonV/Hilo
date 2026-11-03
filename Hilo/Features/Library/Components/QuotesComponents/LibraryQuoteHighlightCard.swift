import SwiftUI

/// A larger, presentation-focused quote card for the library.
///
/// The background is intentionally kept in this component so it can later be
/// replaced by selectable themes or a Metal-backed renderer without changing
/// the library layout.
struct LibraryQuoteHighlightCard: View {
    let quote: Quote

    private var sourceTitle: String {
        let title = quote.bookContext?.book?.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        return title?.isEmpty == false ? title! : String(localized: "quote_unknown_book")
    }

    private var coverURL: String? {
        guard let value = quote.bookContext?.edition?.coverURL,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return value
    }

    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: quote.createdAt) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: quote.createdAt)
        }()

        guard let date else { return "" }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    private var displayQuote: String {
        let value = quote.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count > 120 else { return value }
        return String(value.prefix(117)) + "..."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 24, height: 28, alignment: .leading)
                    .accessibilityHidden(true)

                Spacer()
            }

            Text(displayQuote)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 92, maxHeight: 92, alignment: .topLeading)

            HStack(alignment: .bottom, spacing: 12) {
                HStack(spacing: 10) {
                    if let coverURL {
                        BookCoverView(url: coverURL, width: 34, height: 48)
                    } else {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(.white.opacity(0.16))
                            .frame(width: 34, height: 48)
                            .overlay {
                                Image(systemName: "book.closed")
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                    }

                    Text(sourceTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    if let pageNumber = quote.pageNumber {
                        Text(String(format: String(localized: "reading_page_number"), pageNumber))
                    }
                    if !formattedDate.isEmpty {
                        Text(formattedDate)
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 78, height: 48, alignment: .bottomTrailing)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(height: 48, alignment: .bottom)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240, alignment: .leading)
        .background {
            if coverURL != nil {
                CoverMetalBackground(coverURL: coverURL)
            } else {
                glassBackground
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(displayQuote)
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.primaryStrong.opacity(0.72))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.06))
            }
    }
}
