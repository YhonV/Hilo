import SwiftUI

@Observable
class BookDetailViewModel {

    var book: Book
    var bookStatus: BookStatus?
    var isInitialLoading: Bool = true
    
    private var libraryService = LibraryService.shared
    private var openLibraryService = OpenLibraryService.shared
    private var googleBooksService = GoogleBooksService.shared
    
    init(book: Book) {
        self.book = book
    }

    // MARK: - Obtener estado del libro
    func getBooksFromUserLibrary(userId: UUID) async throws {
        bookStatus = try await libraryService.getBookStatusFromUserLibrary(
            book: book,
            userId: userId
        )
    }

    // MARK: - Obtener sinopsis
    func loadDescription() async throws {

        // Si ya tenemos descripción, no hacemos otra petición
        guard book.description?.isEmpty != false else {
            return
        }

        book.description = try await openLibraryService.getDescription(
            workId: book.externalId
        )
    }
    
    // MARK: - Obtener detalles del libro
    func loadBookDetails() async throws {

        let work = try await openLibraryService.getWorkDetails(
            workId: book.externalId
        )

        // Géneros
        if book.genre.isEmpty {
            book.genre = openLibraryService.extractGenres(
                from: work.subjects ?? []
            )
        }

        // Sinopsis de la edición seleccionada
        if book.description?.isEmpty != false {
            do {
                let googleDescription = try await googleBooksService.getDescription(
                    title: book.title,
                    authors: book.authors,
                    language: book.language
                )

                if let googleDescription {
                    print("USANDO DESCRIPCIÓN GOOGLE")
                    book.description = googleDescription
                }

            } catch {
                print("Error Google Books:", error)
            }
        }

        if book.description?.isEmpty != false {
            print("USANDO DESCRIPCIÓN OPEN LIBRARY")
            book.description = work.description?.value
        }
    }

    // MARK: - Guardar libro
    func saveBook(status: BookStatus) async throws {

        let previousStatus = bookStatus
        bookStatus = status

        do {
            try await libraryService.saveBookToLibrary(
                book: book,
                status: status
            )

        } catch {
            bookStatus = previousStatus
            throw error
        }
    }
    
}
