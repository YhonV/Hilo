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
    private let originalBook: Book

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
        let protectedKeys = ranked.filter { protectedIDs.contains($0.key) }
            .reduce(into: Set<String>()) { $0.formUnion($1.presentationDuplicateKeys) }
        var seenIDs = Set<String>()
        var seenKeys = Set<String>()
        return ranked.filter { edition in
            guard seenIDs.insert(edition.key).inserted else { return false }
            // Keep saved and manually selected records visible even if they share artwork.
            if protectedIDs.contains(edition.key) { return true }
            guard edition.displayCoverURL != nil else { return false }
            let keys = edition.presentationDuplicateKeys
            guard keys.isDisjoint(with: protectedKeys), keys.isDisjoint(with: seenKeys) else { return false }
            seenKeys.formUnion(keys)
            return true
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
        self.originalBook = book
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

        // Each provider can succeed independently; edition changes must not change the query.
        async let workTask: OpenLibraryWorkDTO? = {
            do {
                return try await openLibraryService.getWorkDetails(workId: originalBook.externalId)
            } catch {
                print("Error Open Library:", error)
                return nil
            }
        }()

        async let googleTask: String? = {
            guard needsDescription else { return nil }
            do {
                return try await googleBooksService.getDescription(
                    title: originalBook.title,
                    authors: originalBook.authors,
                    language: originalBook.language
                )
            } catch {
                print("Error Google Books:", error)
                return nil
            }
        }()

        let (work, googleDescription) = await (workTask, googleTask)
        guard !Task.isCancelled else { return }
        if book.genre.isEmpty, let work {
            book.genre = openLibraryService.extractGenres(from: work.subjects ?? [])
        }
        if book.description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            let descriptions = [googleDescription, work?.description?.value]
            if let description = descriptions.compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) })
                .first(where: { !$0.isEmpty }) {
                book.description = description
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
            if let id = originalBook.editionId,
               id.range(of: #"^/books/OL[0-9]+M$"#, options: .regularExpression) != nil {
                var edition = editions.first(where: { $0.key == id }) ?? OpenLibraryEditionDTO(
                    key: id, title: originalBook.title, covers: nil,
                    languages: [OpenLibraryLanguageDTO(key: originalBook.language)],
                    isbn10: nil, isbn13: originalBook.isbn.map { [$0] },
                    publishers: [originalBook.editorial], numberOfPages: originalBook.numberOfPages,
                    publishDate: originalBook.publishedDate
                )
                if !originalBook.cover.isEmpty { edition.persistedCoverURL = originalBook.cover }
                applyEdition(edition)
            } else if !originalBook.cover.isEmpty {
                // Search can return a work cover without an edition ID. Match that cover
                // before selecting; never silently substitute a different edition.
                let identity = originalBook.cover.replacingOccurrences(
                    of: #"-[SML]\.jpg"#, with: ".jpg", options: .regularExpression)
                if let edition = editions.first(where: {
                    $0.displayCoverURL?.absoluteString.replacingOccurrences(
                        of: #"-[SML]\.jpg"#, with: ".jpg", options: .regularExpression) == identity
                }) {
                    applyEdition(edition)
                }
            } else if let edition = displayEditions.first {
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
