//
//  SearchViewModel.swift
//  Hilo
//
//  Created by Cactu on 09-08-26.
//
import SwiftUI

@Observable
class SearchViewModel {
    var books: [Book] = []
    var searchText: String = ""
    var hasLoadedInitialBooks: Bool = false
    
    // MARK: - Función cargar libros iniciales (Luego será mejorada, enviando generos favoritos del usuario)
    func loadInitialBooks() async throws {
        guard !hasLoadedInitialBooks else { return }
        let query = "Harry Potter y la orden del fenix"
        let fetchedBooks = try await GoogleBooksService.shared.searchBook( query: query)
        books = sortBooks(fetchedBooks, query: query)
        if let firstBook = books.first,
           firstBook.cover.isEmpty {

            await GoogleBooksService.shared.debugCover(
                for: firstBook
            )
        }
        hasLoadedInitialBooks = true
    }
    
    // MARK: - Función de buscar libros
    func searchBooks() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        do {
            let fetchedBooks = try await GoogleBooksService.shared.searchBook(query: query)
            books = sortBooks(fetchedBooks, query: query)
            if let firstBook = books.first,
               firstBook.cover.isEmpty {

                await GoogleBooksService.shared.debugCover(
                    for: firstBook
                )
            }
        } catch {
            print("Error cargando libros: \(error)")
        }
    }
    
    // MARK: - Función que generará un score de los libros buscados, con esto ordenaré en el buscador
    func completenessScore(book: Book) -> Int {
        var score = 0
        
        if !book.cover.isEmpty { score += 2 }
        if !book.authors.isEmpty { score += 2 }
        if !(book.isbn ?? "").isEmpty { score += 2 } // se comprueba que no esté vacío
        if let pages = book.numberOfPages, pages > 0 { score += 2 }
        if book.editorial != "Editorial desconocida" { score += 1 }
        if !(book.description ?? "").isEmpty { score += 1}
        if !book.genre.isEmpty { score += 1 }
        if !(book.publishedDate ?? "").isEmpty { score += 1 }
        if let rating = book.averageRating, rating > 0 { score += 1 }
        if book.totalReviews > 0 { score += 1 }
        
        return score
    }
    
    //MARK: - Determinamos si un libro realmente es relevante o no
    private func relevanceScore(book: Book, query: String) -> Int {

        let normalizedQuery = normalizeText(query)
        let normalizedTitle = normalizeText(book.title)

        guard !normalizedQuery.isEmpty else {
            return 0
        }

        let queryWords = normalizedQuery.split(separator: " ")
        let titleWords = normalizedTitle.split(separator: " ")

        // 1. Título exactamente igual
        if normalizedTitle == normalizedQuery {
            return 100
        }

        // 2. Caso especial para búsquedas de una sola palabra
        if queryWords.count == 1,
           let searchedWord = queryWords.first {

            // "It (Eso)"
            if titleWords.first == searchedWord {

                let extraWords = max(titleWords.count - 1, 0)

                return max(
                    80 - (extraWords * 8),
                    55
                )
            }

            // "Debug It", "Act Like It", etc.
            if titleWords.contains(searchedWord) {

                let extraWords = max(titleWords.count - 1, 0)

                return max(
                    50 - (extraWords * 4),
                    25
                )
            }

            return 0
        }

        // 3. La búsqueda completa aparece al comienzo del título
        if normalizedTitle.hasPrefix(normalizedQuery) {
            return 85
        }

        // 4. La búsqueda completa aparece dentro del título
        if normalizedTitle.contains(normalizedQuery) {
            return 70
        }

        // 5. Comparación por palabras del título
        let queryWordsSet = Set(queryWords)
        let titleWordsSet = Set(titleWords)

        let titleMatches = queryWordsSet.intersection(titleWordsSet)

        // Palabras que todavía no encontramos en el título
        let remainingWords = queryWordsSet.subtracting(titleMatches)

        // 6. Buscar esas palabras en los autores
        let authorWords = Set(
            book.authors.flatMap {
                normalizeText($0).split(separator: " ")
            }
        )

        let authorMatches = remainingWords.intersection(authorWords)

        let titleCoverage =
            Double(titleMatches.count) /
            Double(queryWordsSet.count)

        let authorCoverage =
            Double(authorMatches.count) /
            Double(queryWordsSet.count)

        var score = 0

        // El título pesa más
        score += Int(titleCoverage * 60)

        // El autor complementa la búsqueda
        score += Int(authorCoverage * 40)

        // Si encontramos toda la query entre título + autor
        let totalMatches = titleMatches.union(authorMatches)

        if totalMatches.count == queryWordsSet.count {
            score += 20
        }

        // Penalizar títulos demasiado largos
        let extraTitleWords = max(
            titleWordsSet.count - titleMatches.count,
            0
        )

        score -= min(extraTitleWords * 2, 20)

        return max(score, 0)
    }
    
    // MARK: - Función helper para normalizar texto
    func normalizeText(_ text: String) -> String {
        text
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .components(separatedBy: .punctuationCharacters)
            .joined(separator: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
    
    // MARK: - Función para sortear los libros
    private func sortBooks(_ books: [Book],query: String) -> [Book] {

        books.enumerated()
            .sorted { first, second in

                let firstRelevance = relevanceScore(
                    book: first.element,
                    query: query
                )

                let secondRelevance = relevanceScore(
                    book: second.element,
                    query: query
                )

                if firstRelevance != secondRelevance {
                    return firstRelevance > secondRelevance
                }

                let firstCompleteness = completenessScore(
                    book: first.element
                )

                let secondCompleteness = completenessScore(
                    book: second.element
                )

                if firstCompleteness != secondCompleteness {
                    return firstCompleteness > secondCompleteness
                }

                return first.offset < second.offset
            }
            .map(\.element)
    }
    
}
