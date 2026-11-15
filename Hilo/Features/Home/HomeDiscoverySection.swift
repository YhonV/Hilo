import SwiftUI

struct HomeDiscoverySection: View {
    let userID: UUID
    let books: [UserLibraryBook]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var model = HomeDiscoveryViewModel()

    private var libraryKey: String {
        userID.uuidString + books.map { $0.bookId.uuidString }.sorted().joined()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                    : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
                layout {
                    Text(String(localized: "home_discovery_title"))
                        .font(.headline)
                        .fixedSize(horizontal: true, vertical: false)
                    Text(model.favoriteGenres.isEmpty
                         ? String(localized: "home_discovery_explore")
                         : String(localized: "home_discovery_library_genres"))
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 0)
                Button {
                    Task { await model.load(userID: userID, books: books, force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColors.accent)
                .disabled(model.isLoading)
                .accessibilityLabel(String(localized: "search_discover_refresh"))
            }

            if !model.favoriteGenres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(model.favoriteGenres, id: \.self) { genre in
                            NavigationLink {
                                GenreBooksView(genre: genre)
                            } label: {
                                GenrePill(genre: genre)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if model.isLoading && model.suggestions.isEmpty {
                ProgressView().frame(maxWidth: .infinity, minHeight: 180)
            } else if model.failed && model.suggestions.isEmpty {
                Text(String(localized: "home_discovery_error"))
                    .font(.subheadline)
                    .foregroundStyle(AppColors.titles)
            } else if model.suggestions.isEmpty {
                Text(String(localized: "home_discovery_empty"))
                    .font(.subheadline)
                    .foregroundStyle(AppColors.titles)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 16) {
                        ForEach(model.suggestions) { suggestion in
                            NavigationLink {
                                BookDetailView(book: suggestion.book)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    BookCoverView(url: suggestion.book.cover, width: 112, height: 164)
                                    Text(suggestion.book.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppColors.titles)
                                        .lineLimit(2, reservesSpace: true)
                                    Text(suggestion.book.authors.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(AppColors.titles)
                                        .lineLimit(1)
                                    GenrePill(genre: suggestion.genre, compact: true)
                                }
                                .frame(width: 128, alignment: .leading)
                                .multilineTextAlignment(.leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                if model.isLoading { ProgressView().frame(maxWidth: .infinity) }
            }
        }
        .task(id: libraryKey) {
            await model.load(userID: userID, books: books)
        }
    }
}
