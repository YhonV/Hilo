"""Run isolated race regression checks against the actual view model with service doubles.
Usage: python3 Tests/check_saved_edition.py (requires Xcode's Swift compiler).
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
def read(path):
    return (root / path).read_text()

service = read('Hilo/Services/LibraryService.swift')
source = '\n'.join([
    'import Foundation\nimport SwiftUI',
    'enum BookGenre: String, Codable { case fiction }',
    read('Hilo/Models/Book.swift'),
    read('Hilo/Models/BookStatus.swift'),
    read('Hilo/Models/OpenLibraryModels.swift'),
    service[service.index('struct SavedLibrarySelection'):service.index('struct LibraryStatus')],
    '''
@MainActor final class LibraryService {
    static let shared = LibraryService()
    var pending: CheckedContinuation<SavedLibrarySelection?, Error>?
    func getSavedSelection(book: Book, userId: UUID) async throws -> SavedLibrarySelection? {
        try await withCheckedThrowingContinuation { pending = $0 }
    }
    func saveBookToLibrary(book: Book, status: BookStatus) async throws {}
}
@MainActor final class OpenLibraryService {
    static let shared = OpenLibraryService()
    var pending: CheckedContinuation<[OpenLibraryEditionDTO], Error>?
    func getEditions(workId: String) async throws -> [OpenLibraryEditionDTO] {
        try await withCheckedThrowingContinuation { pending = $0 }
    }
    func getDescription(workId: String) async throws -> String? { nil }
    func getWorkDetails(workId: String) async throws -> OpenLibraryWorkDTO {
        OpenLibraryWorkDTO(description: nil, subjects: nil)
    }
    func extractGenres(from: [String]) -> [BookGenre] { [] }
}
@MainActor final class GoogleBooksService {
    static let shared = GoogleBooksService()
    func getDescription(title: String, authors: [String], language: String) async throws -> String? { nil }
}
''',
    read('Hilo/Features/Search/ViewModels/BookDetailViewModel.swift'),
    r'''
@main struct Checks {
    @MainActor static func main() async throws {
        let base = Book(externalId: "/works/OL1W", title: "Work", authors: [], cover: "search-cover",
                        genre: [], totalReviews: 0, editorial: "", language: "")
        let a = OpenLibraryEditionDTO(key: "/books/OL1M", title: "A", covers: [1], languages: nil,
             isbn10: nil, isbn13: nil, publishers: nil, numberOfPages: 10, publishDate: nil)
        let b = OpenLibraryEditionDTO(key: "/books/OL2M", title: "B", covers: nil, languages: nil,
             isbn10: nil, isbn13: nil, publishers: nil, numberOfPages: 20, publishDate: nil)
        let saved = try JSONDecoder().decode(SavedLibrarySelection.self, from: Data(#"{"status_id":1,"book_editions":{"open_library_edition_id":"/books/OL3M","isbn":"123","publisher":"Saved","language":"spa","number_of_pages":321,"published_date":"2000","cover_url":"https://example.com/saved.jpg"}}"#.utf8))
        // Saved edition deliberately absent from remote batch. Exercise both arrival orders and manual intent.
        for libraryFirst in [false, true] {
            for manual in [false, true] {
                let vm = BookDetailViewModel(book: base)
                let libraryTask = Task { try await vm.getBooksFromUserLibrary(userId: UUID()) }
                let editionsTask = Task { await vm.loadEditions() }
                while LibraryService.shared.pending == nil || OpenLibraryService.shared.pending == nil { await Task.yield() }
                if manual { vm.selectEdition(b) }
                if libraryFirst {
                    LibraryService.shared.pending?.resume(returning: saved)
                    LibraryService.shared.pending = nil
                    try await libraryTask.value
                    OpenLibraryService.shared.pending?.resume(returning: [a])
                    OpenLibraryService.shared.pending = nil
                    await editionsTask.value
                } else {
                    OpenLibraryService.shared.pending?.resume(returning: [a])
                    OpenLibraryService.shared.pending = nil
                    await editionsTask.value
                    LibraryService.shared.pending?.resume(returning: saved)
                    LibraryService.shared.pending = nil
                    try await libraryTask.value
                }
                assert(vm.book.editionId == (manual ? b.key : "/books/OL3M"))
                assert(vm.bookStatus == .reading)
                assert(vm.editions.contains { $0.key == vm.book.editionId })
                assert(vm.book.cover == (manual ? "" : "https://example.com/saved.jpg"))
                assert(vm.book.numberOfPages == (manual ? 20 : 321))
                assert(vm.canSaveEdition)
            }
        }
        for missing in [false, true] {
            let vm = BookDetailViewModel(book: base)
            let libraryTask = Task { try await vm.getBooksFromUserLibrary(userId: UUID()) }
            while LibraryService.shared.pending == nil { await Task.yield() }
            LibraryService.shared.pending?.resume(returning: missing ? SavedLibrarySelection(statusId: 2, edition: nil) : nil)
            LibraryService.shared.pending = nil
            try await libraryTask.value
            let editionsTask = Task { await vm.loadEditions() }
            while OpenLibraryService.shared.pending == nil { await Task.yield() }
            OpenLibraryService.shared.pending?.resume(returning: [a])
            OpenLibraryService.shared.pending = nil
            await editionsTask.value
            assert(vm.book.editionId == (missing ? nil : a.key))
            assert(vm.canSaveEdition == !missing)
        }
        let vm = BookDetailViewModel(book: base)
        let failed = Task { try await vm.getBooksFromUserLibrary(userId: UUID()) }
        while LibraryService.shared.pending == nil { await Task.yield() }
        LibraryService.shared.pending?.resume(throwing: URLError(.notConnectedToInternet))
        LibraryService.shared.pending = nil
        do { try await failed.value; assertionFailure("Expected failure") } catch {}
        assert(!vm.canSaveEdition && vm.librarySelectionError != nil)
        vm.selectEdition(b)
        assert(vm.canSaveEdition && vm.book.cover.isEmpty)
        func edition(_ id: Int, cover: Int?, language: String = "eng", complete: Bool = false) -> OpenLibraryEditionDTO {
            OpenLibraryEditionDTO(key: "/books/OL\(id)M", title: "Edition \(id)",
                covers: cover.map { [$0] }, languages: [OpenLibraryLanguageDTO(key: "/languages/\(language)")],
                isbn10: nil, isbn13: complete ? ["1234567890123"] : nil,
                publishers: complete ? ["Publisher"] : nil, numberOfPages: complete ? 100 : nil,
                publishDate: complete ? "October 12, 2001" : nil)
        }
        let carousel = BookDetailViewModel(book: base, deviceLanguage: "es")
        carousel.editions = [edition(10, cover: nil), edition(11, cover: -1),
            edition(12, cover: 12, complete: true), edition(13, cover: 13, language: "spa"),
            edition(14, cover: 13, language: "spa", complete: true)]
        assert(carousel.displayEditions.map(\.key) == ["/books/OL14M", "/books/OL12M"])
        assert(carousel.editions.count == 5) // presentation must not mutate source editions
        assert(carousel.displayEditions.first?.publicationYear == "2001")
        var persistedSize = edition(15, cover: nil)
        persistedSize.persistedCoverURL = "https://covers.openlibrary.org/b/id/13-L.jpg"
        assert(persistedSize.coverIdentity == carousel.editions[3].coverIdentity)
        carousel.editions = (20..<35).map { edition($0, cover: $0) }
        assert(carousel.visibleEditions.count == 10)
        let initialOrder = carousel.visibleEditions.map(\.key)
        for item in carousel.visibleEditions {
            carousel.selectEdition(item)
            assert(carousel.visibleEditions.map(\.key) == initialOrder)
        }
        carousel.showsAllEditions = true
        assert(carousel.visibleEditions.count == 15)
        let expandedOrder = carousel.visibleEditions.map(\.key)
        for item in carousel.visibleEditions {
            carousel.selectEdition(item)
            assert(carousel.visibleEditions.map(\.key) == expandedOrder)
        }
        carousel.selectEdition(carousel.editions.last!)
        carousel.showsAllEditions = false
        assert(carousel.visibleEditions.count == 10)
        assert(carousel.visibleEditions.contains { $0.key == "/books/OL34M" })
        let collapsedOrder = carousel.visibleEditions.map(\.key)
        for item in carousel.visibleEditions {
            carousel.selectEdition(item)
            assert(carousel.visibleEditions.map(\.key) == collapsedOrder)
        }
        let savedWithoutCover = try JSONDecoder().decode(SavedLibrarySelection.self, from:
            Data(#"{"status_id":1,"book_editions":{"open_library_edition_id":"/books/OL99M"}}"#.utf8))
        let restore = Task { try await carousel.getBooksFromUserLibrary(userId: UUID()) }
        while LibraryService.shared.pending == nil { await Task.yield() }
        LibraryService.shared.pending?.resume(returning: savedWithoutCover)
        LibraryService.shared.pending = nil
        try await restore.value
        assert(carousel.visibleEditions.first?.key == "/books/OL99M")
        assert(carousel.selectedEdition?.key == "/books/OL34M")
        assert(carousel.visibleEditions.count == 10)
        print("PASS: cover filtering/deduplication, language/metadata ordering, initial limit, expansion, saved coverless edition and retained manual selection")
        print("PASS: arrival orders, manual selection, persisted fallback, missing edition, unsaved work, network failure")
    }
}
'''])
with tempfile.TemporaryDirectory(prefix='hilo-tests-') as tmp:
    path = Path(tmp)
    (path / 'Checks.swift').write_text(source)
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', '-module-cache-path', str(path / 'cache'), str(path / 'Checks.swift'), '-o', str(path / 'checks')], check=True)
    subprocess.run([str(path / 'checks')], check=True)
