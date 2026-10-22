import SwiftUI

@Observable
class BookDetailViewModel {

    var book: Book
    var bookStatus: BookStatus?
    var isInitialLoading: Bool = true
    
    private var libraryService = LibraryService.shared
    private var openLibraryService = OpenLibraryService.shared
    private var googleBooksService = GoogleBooksService.shared
    
    // MARK: - Ediciones
    var editions: [OpenLibraryEditionDTO] = []
    var selectedEdition: OpenLibraryEditionDTO?
    var isLoadingEditions = false
    var editionsError: String?
    
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
    
    // MARK: - Obtener ediciones
    func loadEditions() async {

        guard !isLoadingEditions else { return }

        isLoadingEditions = true
        editionsError = nil

        defer { isLoadingEditions = false }

        do {
            let availableEditions = try await openLibraryService.getEditions(
                workId: book.externalId
            )

            // Priorizar ediciones que tengan portada
            editions = availableEditions.sorted {
                ($0.covers?.isEmpty == false ? 1 : 0) >
                ($1.covers?.isEmpty == false ? 1 : 0)
            }

            // Si ya existe una edición seleccionada, conservarla.
            if let editionId = book.editionId,
               let edition = editions.first(where: { $0.key == editionId }) {

                selectedEdition = edition
                return
            }

            // Seleccionar inicialmente una edición con portada.
            if let firstEdition = editions.first {
                selectEdition(firstEdition)
            }

        } catch {
            editionsError = error.localizedDescription
        }
    }
    
    // MARK: - Seleccionar edición
    func selectEdition(_ edition: OpenLibraryEditionDTO) {

        selectedEdition = edition

        book.editionId = edition.key
        book.title = edition.title

        if let coverId = edition.covers?.first {
            book.cover = "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
        }

        book.isbn = edition.isbn13?.first
            ?? edition.isbn10?.first

        book.editorial = edition.publishers?.first
            ?? "Editorial desconocida"

        book.numberOfPages = edition.numberOfPages
        book.publishedDate = edition.publishDate

        book.language = edition.languages?.first?.key
            .replacingOccurrences(
                of: "/languages/",
                with: ""
            ) ?? "unknown"
    }
    
}
