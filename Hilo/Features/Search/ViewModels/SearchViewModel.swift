//
//  SearchViewModel.swift
//  Hilo
//
//  Created by Cactu on 09-08-26.
//
import SwiftUI

@MainActor
@Observable
class SearchViewModel {
    var books: [Book] = []
    var searchText: String = ""
    var hasLoadedInitialBooks: Bool = false
    private var initialBooks: [Book] = []
    private var lastSearchQuery: String?
    private var searchCache: [String: [Book]] = [:]
    private var recommendationsTask: Task<Void, Never>?
    var recommendedBooks: [Book] = []
    var recommendationsIsLoading = false
    var hasSearched = false
    var recentSearches: [String] = []
    var discoveryBooks: [Book] = []
    var discoveryIsLoading = false
    
    // MARK: - Función cargar libros iniciales (Luego será mejorada, enviando generos favoritos del usuario)
    func loadInitialBooks() async throws {
        guard !hasLoadedInitialBooks else { return }

        let query = "Harry Potter"

        let fetchedBooks = try await OpenLibraryService.shared.searchBooks(query: query)
        
        books = fetchedBooks
        initialBooks = fetchedBooks

        hasLoadedInitialBooks = true
    }
    
    // MARK: - Función de buscar libros
    func searchBooks() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        guard query != lastSearchQuery else { return }
        recommendationsTask?.cancel()
        hasSearched = false
        books = []
        recommendedBooks = []
        do {
            let fetchedBooks: [Book]
            if let cached = searchCache[query] {
                fetchedBooks = cached
            } else {
                fetchedBooks = try await OpenLibraryService.shared.searchBooks(query: query)
            }

            let sortedBooks = fetchedBooks.sorted { firstBook, secondBook in

                let firstScore = titleMatchScore(title: firstBook.title, query: query)

                let secondScore = titleMatchScore(title: secondBook.title, query: query)

                return firstScore > secondScore
            }

            try Task.checkCancellation()
            guard searchText.trimmingCharacters(in: .whitespacesAndNewlines) == query else { return }

            books = sortedBooks
            if searchCache.count >= 20 { searchCache.removeAll() }
            searchCache[query] = sortedBooks
            lastSearchQuery = query
            hasSearched = true
            SearchHistoryService.shared.saveSearch(query)
            loadRecentSearches()
            
            recommendationsTask = Task {
                await getRecommendedBooks()
            }

        } catch is CancellationError {
            return

        } catch {
            print("Error cargando libros: \(error)")
        }
    }
    
    func restoreInitialBooks() {
        recommendationsTask?.cancel()
        books = initialBooks
        recommendedBooks = []
        hasSearched = false
        lastSearchQuery = nil
    }
    
    private func titleMatchScore(title: String, query: String) -> Int {

        let normalizedTitle = title.lowercased()
        let normalizedQuery = query.lowercased()

        if normalizedTitle == normalizedQuery {
            return 100
        }

        if normalizedTitle.hasPrefix(normalizedQuery) {
            return 80
        }

        if normalizedTitle.contains(normalizedQuery) {
            return 60
        }

        return 0
    }
    
    // MARK: - Recomendación de libros
    func getRecommendedBooks() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let mainBook = books.first,
              let author = mainBook.authors.first,
              !author.isEmpty else {
            recommendedBooks = []
            return
        }
        
        recommendationsIsLoading = true
        defer {
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines) == query {
                recommendationsIsLoading = false
            }
        }

        do {
            let fetchedBooks = try await OpenLibraryService.shared.searchBooks(
                query: "author:\"\(author)\""
            )

            try Task.checkCancellation()

            guard searchText.trimmingCharacters(in: .whitespacesAndNewlines) == query else { return }
            let existingIds = Set(books.map(\.externalId))

            recommendedBooks = Array(
                fetchedBooks.filter { book in
                    !existingIds.contains(book.externalId)
                    && book.authors.contains {
                        $0.compare(author, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
                    }
                }
                .prefix(8)
            )

        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            recommendedBooks = []
            print("Error cargando recomendaciones: \(error)")
        }
    }
    
    // MARK: - Obtener búsquedas recientes
    func loadRecentSearches() {
        recentSearches = SearchHistoryService.shared.getRecentSearches()
    }
    
    // MARK: - Eliminar historial de búsquedas
    func clearRecentSearches() {
        SearchHistoryService.shared.clearHistory()
        recentSearches = []
    }
    
    
    // MARK: - Descubrir libros
    
    func loadDiscoveryBooks(forceRefresh: Bool = false) async {
        guard !discoveryIsLoading else { return }
        guard forceRefresh || discoveryBooks.isEmpty else { return }


        discoveryIsLoading = true
        defer { discoveryIsLoading = false }

        let queries = [
            "subject:fantasy",
            "subject:science_fiction",
            "subject:mystery",
            "subject:romance",
            "subject:horror",
            "subject:adventure",
            "subject:thriller",
            "subject:historical_fiction",
            "subject:dystopian_fiction",
            "subject:young_adult_fiction"
        ]

        let selectedQueries = Array(queries.shuffled().prefix(4))

        do {
            let results = await withTaskGroup(of: [Book].self) { group in

                for query in selectedQueries {
                    group.addTask {
                        do {
                            return try await OpenLibraryService.shared.searchBooks(
                                query: query,
                                offset: Int.random(in: 0...5) * 20
                            )
                        } catch {
                            return []
                        }
                    }
                }

                var allResults: [[Book]] = []

                for await books in group {
                    allResults.append(books)
                }

                return allResults
            }

            try Task.checkCancellation()

            var discoveredBooks: [Book] = []
            var existingIds = Set<String>()

            for books in results {
                let candidates = books.filter {
                    !$0.cover.isEmpty &&
                    !existingIds.contains($0.externalId)
                }

                for book in candidates.prefix(2) {
                    discoveredBooks.append(book)
                    existingIds.insert(book.externalId)
                }
            }

            discoveryBooks = discoveredBooks

        } catch is CancellationError {
            return
        } catch {
            print("Error cargando libros para descubrir:", error)
        }
    }


}
