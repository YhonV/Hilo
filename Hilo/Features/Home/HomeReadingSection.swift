import SwiftUI

struct HomeReadingSection: View {
    let books: [UserLibraryBook]

    private var readingBooks: [UserLibraryBook] {
        books.filter { $0.status.name == "reading" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "profile_currently_reading"))
                    .font(.headline)
                Spacer()
                if !readingBooks.isEmpty {
                    Text(readingBooks.count.formatted())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppColors.accent.opacity(0.08), in: Capsule())
                        .accessibilityHidden(true)
                }
            }

            if readingBooks.isEmpty {
                EmptyLibraryBooksView(status: .reading)
            } else if readingBooks.count == 1, let book = readingBooks.first {
                HomeReadingBookCard(book: book)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(readingBooks, id: \.userBookId) { book in
                            HomeReadingBookCard(book: book)
                                .containerRelativeFrame(.horizontal) { width, _ in
                                    max(0, width - 24)
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }
}

private struct HomeReadingBookCard: View {
    let book: UserLibraryBook
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsProgressEditor = false

    private var totalPages: Int? {
        guard let total = book.edition.numberOfPages, total > 0 else { return nil }
        return total
    }

    private var pagesRead: Int {
        let page = max(0, book.currentPage ?? 0)
        return totalPages.map { min(page, $0) } ?? page
    }

    private var progress: Double? {
        totalPages.map { Double(pagesRead) / Double($0) }
    }

    private var authors: String {
        let names = book.book.bookAuthors.map(\.author.name).filter { !$0.isEmpty }
        return names.isEmpty ? String(localized: "book_unknown_author") : names.joined(separator: ", ")
    }

    private var startDate: Date? {
        guard let raw = book.startedAt else { return nil }
        let timestamp = ISO8601DateFormatter()
        timestamp.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = timestamp.date(from: raw) { return date }
        timestamp.formatOptions = [.withInternetDateTime]
        if let date = timestamp.date(from: raw) { return date }
        let dateOnly = DateFormatter()
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.calendar = Calendar(identifier: .gregorian)
        dateOnly.dateFormat = "yyyy-MM-dd"
        return dateOnly.date(from: raw)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            NavigationLink {
                LibraryBookDetailView(bookDetail: book)
            } label: {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 16) { cover; bookInfo }
                    } else {
                        HStack(alignment: .top, spacing: 16) { cover; bookInfo }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(localized: "home_reading_progress"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    if let progress {
                        Text(progress, format: .percent.precision(.fractionLength(0)))
                            .font(.title2.bold())
                            .monospacedDigit()
                    } else {
                        Text(String(localized: "home_reading_total_unknown"))
                            .font(.caption)
                    }
                }

                if let progress {
                    GeometryReader { geometry in
                        Capsule().fill(.white.opacity(0.18))
                        Capsule().fill(.white.opacity(0.9))
                            .frame(width: geometry.size.width * progress)
                    }
                    .frame(height: 5)
                    .accessibilityHidden(true)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                metric(pagesRead.formatted(), label: String(localized: "pages_read"))
                if let totalPages {
                    metric((totalPages - pagesRead).formatted(), label: String(localized: "home_reading_pages_left"))
                    metric(totalPages.formatted(), label: String(localized: "home_reading_total_pages"))
                }
            }

            Button {
                showsProgressEditor = true
            } label: {
                Label(String(localized: "reading_update_progress"), systemImage: "book.pages")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 8)
                    .background(.white.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background {
            ReadingCoverBackground(coverURL: book.edition.coverUrl)
                .clipShape(RoundedRectangle(cornerRadius: 26))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .sheet(isPresented: $showsProgressEditor) {
            ReadingActionSheetView(bookDetail: book)
                .presentationDetents([.height(380), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var cover: some View {
        BookCoverView(url: book.edition.coverUrl ?? "", width: 86, height: 130)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .accessibilityHidden(true)
    }

    private var bookInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(book.book.title)
                .font(.title3.weight(.semibold))
                .lineLimit(3, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Text(authors)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
            Label {
                if let startDate {
                    Text(String(format: String(localized: "home_reading_started"),
                                startDate.formatted(date: .abbreviated, time: .omitted)))
                } else {
                    Text(String(localized: "home_reading_start_unknown"))
                }
            } icon: {
                Image(systemName: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metric(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title3.bold()).monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
