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

        let needsDescription = book.description?.isEmpty != false

        async let workTask = openLibraryService.getWorkDetails(
            workId: book.externalId
        )

        async let googleTask: String? = {
            guard needsDescription else { return nil }

            do {
                return try await googleBooksService.getDescription(
                    title: book.title,
                    authors: book.authors,
                    language: book.language
                )
            } catch {
                print("Error Google Books:", error)
                return nil
            }
        }()

        let work = try await workTask
        let googleDescription = await googleTask

        if book.genre.isEmpty {
            book.genre = openLibraryService.extractGenres(
                from: work.subjects ?? []
            )
        }

        if needsDescription {
            if let googleDescription, !googleDescription.isEmpty {
                print("USANDO DESCRIPCIÓN GOOGLE")
                book.description = googleDescription
            } else {
                print("USANDO DESCRIPCIÓN OPEN LIBRARY")
                book.description = work.description?.value
            }
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
