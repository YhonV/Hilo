import SwiftUI

struct DiscoveryLibraryEntry {
    let workID: String?
    let title: String
    let genres: [BookGenre]
}

struct DiscoverySuggestion: Identifiable {
    let book: Book
    let genre: BookGenre
    let isExploration: Bool
    var id: String { book.externalId }
}

enum HomeDiscoveryRanking {
    static func favoriteGenres(in library: [DiscoveryLibraryEntry]) -> [BookGenre] {
        var counts: [BookGenre: Int] = [:]
        for entry in library {
            for genre in Set(entry.genres) { counts[genre, default: 0] += 1 }
        }
        return counts.keys.sorted {
            let left = counts[$0, default: 0], right = counts[$1, default: 0]
            return left == right ? $0.rawValue < $1.rawValue : left > right
        }
    }

    static func suggestions(
        from groups: [(genre: BookGenre, books: [Book], exploration: Bool)],
        excluding library: [DiscoveryLibraryEntry]
    ) -> [DiscoverySuggestion] {
        var seenIDs = Set(library.compactMap(\.workID).map(workKey))
        var seenTitles = Set(library.map { titleKey($0.title) })
        var suggestions: [DiscoverySuggestion] = []
        // Interleave pools so one prolific genre doesn't fill the whole carousel.
        let largestPool = groups.map { $0.books.count }.max() ?? 0
        for index in 0..<largestPool {
            for group in groups where index < group.books.count {
                let book = group.books[index]
                let id = workKey(book.externalId)
                let title = titleKey(book.title)
                guard !id.isEmpty, !title.isEmpty, !book.cover.isEmpty,
                      !seenIDs.contains(id), !seenTitles.contains(title) else { continue }
                seenIDs.insert(id)
                seenTitles.insert(title)
                suggestions.append(DiscoverySuggestion(book: book, genre: group.genre, isExploration: group.exploration))
                if suggestions.count == 12 { return suggestions }
            }
        }
        return suggestions
    }

    private static func workKey(_ value: String) -> String {
        value.split(separator: "/").last.map(String.init) ?? value
    }

    private static func titleKey(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.joined(separator: " ")
    }
}

@MainActor
@Observable
final class HomeDiscoveryViewModel {
    private(set) var suggestions: [DiscoverySuggestion] = []
    private(set) var favoriteGenres: [BookGenre] = []
    private(set) var isLoading = false
    private(set) var failed = false
    private var loadedKey: String?
    private var lastLoaded: Date?
    private var requestID = UUID()
    private var page = 0

    func load(userID: UUID, books: [UserLibraryBook], force: Bool = false) async {
        DiscoveryDiagnostics.log("Load requested: books=\(books.count), force=\(force)")
        let key = userID.uuidString + books.map { $0.bookId.uuidString }.sorted().joined()
        if !force, loadedKey == key, let lastLoaded, Date().timeIntervalSince(lastLoaded) < 900 {
            DiscoveryDiagnostics.log("Using recommendations cache: \(suggestions.count) results")
            return
        }
        let token = UUID()
        requestID = token
        if loadedKey != key {
            suggestions = []
            favoriteGenres = []
            page = 0
        } else if force {
            page = (page + 1) % 5
        }
        isLoading = true
        failed = false
        defer { if requestID == token { isLoading = false } }

        do {
            let library = try await HomeDiscoveryService.shared.libraryEntries(books: books, force: force)
            try Task.checkCancellation()
            guard requestID == token else { return }
            let favorites = HomeDiscoveryRanking.favoriteGenres(in: library)
            let preferred = Array(favorites.prefix(3))
            DiscoveryDiagnostics.log("Ranked genres: \(favorites.map(\.rawValue)); using generic fallback: \(preferred.isEmpty)")
            let fallback: [BookGenre] = [.fantasy, .mystery, .scienceFiction]
            let topics = preferred.isEmpty ? fallback : preferred
            var queries = topics.map { (genre: $0, exploration: preferred.isEmpty) }
            if !preferred.isEmpty,
               let extra = BookGenre.allCases.filter({ !favorites.contains($0) }).dropFirst(page % max(1, BookGenre.allCases.count - favorites.count)).first {
                queries.append((genre: extra, exploration: true))
            }
            var pools: [(genre: BookGenre, books: [Book], exploration: Bool)] = []
            var successfulQueries = 0
            for query in queries {
                try Task.checkCancellation()
                do {
                    DiscoveryDiagnostics.log("Search subject=\(query.genre.searchTerm), offset=\(page * 20)")
                    let results = try await OpenLibraryService.shared.searchBooks(
                        query: "subject:\"\(query.genre.searchTerm)\"", offset: page * 20
                    )
                    successfulQueries += 1
                    DiscoveryDiagnostics.log("Search \(query.genre.rawValue): \(results.count) books, \(results.filter { !$0.cover.isEmpty }.count) with cover")
                    pools.append((query.genre, results, query.exploration))
                } catch {
                    DiscoveryDiagnostics.log("Search failed for \(query.genre.rawValue): \(String(reflecting: error))")
                    try Task.checkCancellation()
                    // Other genres may still succeed if one provider request fails.
                }
            }
            try Task.checkCancellation()
            guard requestID == token else { return }
            guard successfulQueries > 0 else { failed = true; return }
            suggestions = HomeDiscoveryRanking.suggestions(from: pools, excluding: library)
            DiscoveryDiagnostics.log("Final: \(pools.reduce(0) { $0 + $1.books.count }) candidates -> \(suggestions.count) recommendations after cover/duplicate/library filtering")
            favoriteGenres = preferred
            loadedKey = key
            lastLoaded = Date()
        } catch {
            DiscoveryDiagnostics.log("Load failed/cancelled: \(String(reflecting: error))")
            guard requestID == token, !Task.isCancelled else { return }
            failed = true
        }
    }
}
