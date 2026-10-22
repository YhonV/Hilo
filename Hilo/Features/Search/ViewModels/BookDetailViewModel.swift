import SwiftUI

@MainActor
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
    var librarySelectionError: String?
    private(set) var savedEdition: OpenLibraryEditionDTO?
    var showsAllEditions = false {
        didSet {
            if oldValue && !showsAllEditions {
                collapsedEditionID = selectedEdition?.key
            }
        }
    }
    private var collapsedEditionID: String?
    private let deviceLanguage: String
    private let originalTitle: String

    // Filtering is presentation-only. Keep the complete batch in `editions`.
    var displayEditions: [OpenLibraryEditionDTO] {
        var candidates = editions
        for protectedEdition in [savedEdition, selectedEdition].compactMap({ $0 }) {
            // Refresh metadata in place: removing and appending changed the tie-break
            // index on every tap, making SwiftUI move the selected card.
            if let index = candidates.firstIndex(where: { $0.key == protectedEdition.key }) {
                candidates[index] = protectedEdition
            } else {
                candidates.append(protectedEdition)
            }
        }
        let ranked = candidates.enumerated().sorted { lhs, rhs in
            let leftSaved = lhs.element.key == savedEdition?.key
            let rightSaved = rhs.element.key == savedEdition?.key
            if leftSaved != rightSaved { return leftSaved }
            let leftLanguage = lhs.element.matchesLanguage(deviceLanguage)
            let rightLanguage = rhs.element.matchesLanguage(deviceLanguage)
            if leftLanguage != rightLanguage { return leftLanguage }
            if lhs.element.metadataScore != rhs.element.metadataScore {
                return lhs.element.metadataScore > rhs.element.metadataScore
            }
            return lhs.offset < rhs.offset
        }.map(\.element)
        let protectedIDs = Set([savedEdition?.key, selectedEdition?.key].compactMap { $0 })
        let protectedCovers = Set(ranked.filter { protectedIDs.contains($0.key) }.compactMap(\.coverIdentity))
        var seenIDs = Set<String>()
        var seenCovers = Set<String>()
        return ranked.filter { edition in
            guard seenIDs.insert(edition.key).inserted else { return false }
            if protectedIDs.contains(edition.key) { return true }
            guard let cover = edition.coverIdentity, !protectedCovers.contains(cover) else { return false }
            return seenCovers.insert(cover).inserted
        }
    }

    var visibleEditions: [OpenLibraryEditionDTO] {
        let all = displayEditions
        guard !showsAllEditions else { return all }
        var visible = Array(all.prefix(10))
        // Retain the collapsed subset until the user expands/collapses again.
        // Subsequent taps must not replace a card or shift its neighbours.
        if let retainedEdition = all.first(where: { $0.key == collapsedEditionID }),
           !visible.contains(where: { $0.key == retainedEdition.key }) {
            if visible.count == 10 { visible.removeLast() }
            visible.append(retainedEdition)
        }
        return visible
    }
    private var hasManualSelection = false
    private var hasSavedAssociation = false

    var canSaveEdition: Bool {
        book.editionId?.range(of: #"^/books/OL[0-9]+M$"#, options: .regularExpression) != nil
    }
    
    init(book: Book, deviceLanguage: String = Locale.current.language.languageCode?.identifier ?? "en") {
        self.deviceLanguage = deviceLanguage
        self.book = book
        self.originalTitle = book.title
    }

    // MARK: - Obtener estado del libro
    func getBooksFromUserLibrary(userId: UUID) async throws {
        do {
            let selection = try await libraryService.getSavedSelection(book: book, userId: userId)
            bookStatus = selection?.status
            hasSavedAssociation = selection != nil
            librarySelectionError = nil
            savedEdition = selection?.edition?.asEdition(title: originalTitle)
            guard selection != nil else { return }
            guard let edition = savedEdition else {
                guard !hasManualSelection else { return }
                clearEdition()
                librarySelectionError = String(localized: "edition_restore_error")
                return
            }
            editions.removeAll { $0.key == edition.key }
            editions.insert(edition, at: 0)
            if !hasManualSelection { applyEdition(edition) }
        } catch {
            // An unavailable library is not evidence that this work is unsaved.
            hasSavedAssociation = true
            if !hasManualSelection {
                clearEdition()
            }
            librarySelectionError = String(localized: "edition_lookup_error")
            throw error
        }
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
        let editionBeingSaved = selectedEdition
        bookStatus = status

        do {
            try await libraryService.saveBookToLibrary(
                book: book,
                status: status
            )
            savedEdition = editionBeingSaved
            hasSavedAssociation = true

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

            editions = availableEditions

            // Preserve the exact snapshot (including persisted cover URLs) and manual choices.
            if let selectedEdition {
                editions.removeAll { $0.key == selectedEdition.key }
                editions.insert(selectedEdition, at: 0)
                return
            }
            guard !hasManualSelection, !hasSavedAssociation else { return }
            if let edition = displayEditions.first {
                applyEdition(edition)
            }

        } catch {
            editionsError = String(localized: "editions_load_error")
        }
    }
    
    // MARK: - Seleccionar edición
    func selectEdition(_ edition: OpenLibraryEditionDTO) {
        hasManualSelection = true
        librarySelectionError = nil
        applyEdition(edition)
    }

    private func clearEdition() {
        selectedEdition = nil
        book.editionId = nil
        book.title = originalTitle
        book.cover = ""
        book.isbn = nil
        book.editorial = String(localized: "book_unknown_publisher")
        book.language = "unknown"
        book.numberOfPages = nil
        book.publishedDate = nil
    }

    private func applyEdition(_ edition: OpenLibraryEditionDTO) {
        selectedEdition = edition

        book.editionId = edition.key
        book.title = edition.title

        book.cover = edition.persistedCoverURL
            ?? edition.covers?.first(where: { $0 > 0 }).map {
                "https://covers.openlibrary.org/b/id/\($0)-L.jpg"
            } ?? ""

        book.isbn = edition.isbn13?.first
            ?? edition.isbn10?.first

        book.editorial = edition.publishers?.first
            ?? String(localized: "book_unknown_publisher")

        book.numberOfPages = edition.numberOfPages
        book.publishedDate = edition.publishDate

        book.language = edition.languages?.first?.key
            .replacingOccurrences(
                of: "/languages/",
                with: ""
            ) ?? "unknown"
    }
    
}
