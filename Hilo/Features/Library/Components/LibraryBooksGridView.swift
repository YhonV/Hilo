import SwiftUI

struct LibraryBooksGridView: View {
    let books: [UserLibraryBook]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.adaptive(minimum: 260), spacing: 12, alignment: .top)]
        }
        if horizontalSizeClass == .compact {
            let count = dynamicTypeSize >= .xxLarge ? 2 : 3
            return Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: count)
        }
        return [GridItem(.adaptive(minimum: 140), spacing: 16, alignment: .top)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
            ForEach(books, id: \.userBookId) { book in
                NavigationLink {
                    LibraryBookDetailView(bookDetail: book)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Color.clear
                            .aspectRatio(2.0 / 3.0, contentMode: .fit)
                            .overlay {
                                AsyncImage(url: URL(string: book.edition.coverUrl ?? "")) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFit()
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppColors.surface)
                                            .overlay {
                                                Image(systemName: "book.closed")
                                                    .font(.title2)
                                                    .foregroundStyle(AppColors.secondaryText)
                                            }
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityHidden(true)

                        Text(book.book.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.titles)
                            .lineLimit(2, reservesSpace: true)

                        let authors = book.book.bookAuthors.map { $0.author.name }.joined(separator: ", ")
                        Text(authors.isEmpty ? String(localized: "book_unknown_author") : authors)
                            .font(.caption2)
                            .foregroundStyle(AppColors.secondaryText)
                            .lineLimit(1)

                        if let page = book.currentPage {
                            if let total = book.edition.numberOfPages, total > 0 {
                                ProgressView(value: min(max(Double(page) / Double(total), 0), 1))
                                    .tint(AppColors.accent)
                                Text(String(format: String(localized: "reading_progress_percentage"), Int(min(max(Double(page) / Double(total), 0), 1) * 100)))
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.secondaryText)
                            } else {
                                Text(String(format: String(localized: "reading_page_number"), page))
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
