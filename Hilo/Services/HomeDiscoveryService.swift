import Foundation
import Supabase

@MainActor
final class HomeDiscoveryService {
    static let shared = HomeDiscoveryService()
    private var cached: [UUID: DiscoveryLibraryEntry] = [:]

    private struct Genre: Decodable { let name: String }
    private struct GenreLink: Decodable { let genres: Genre? }
    private struct Record: Decodable {
        let id: UUID
        let books: Metadata?
        var open_library_work_id: String? { books?.open_library_work_id }
        var book_genres: [GenreLink]? { books?.book_genres }
    }
    private struct Metadata: Decodable {
        let open_library_work_id: String?
        let book_genres: [GenreLink]?
    }

    func libraryEntries(books: [UserLibraryBook], force: Bool = false) async throws -> [DiscoveryLibraryEntry] {
        if force { cached.removeAll() }
        DiscoveryDiagnostics.log("Library input: \(books.count) entries; cached: \(cached.count); force: \(force)")
        guard !books.isEmpty else { return [] }
        let missing = Set(books.map(\.bookId)).filter { cached[$0] == nil }
        if !missing.isEmpty {
            let records: [Record]
            do {
                DiscoveryDiagnostics.log("Query books + book_genres + genres for IDs: \(missing.map(\.uuidString).sorted())")
                let response = try await supabase.from("user_book")
                    .select("id:book_id, books(open_library_work_id, book_genres(genres(name)))")
                    .eq("user_id", value: books[0].userId)
                    .is("deleted_at", value: nil)
                    .in("book_id", values: missing.map(\.uuidString)).execute()
                DiscoveryDiagnostics.log("Supabase response (IDs and genres only): \(String(data: response.data, encoding: .utf8) ?? "<invalid UTF-8>")")
                records = try JSONDecoder().decode([Record].self, from: response.data)
            } catch {
                DiscoveryDiagnostics.log("Genre query/decoding failed: \(String(reflecting: error))")
                try Task.checkCancellation()
                // Older schemas may not expose the genre relation. Work IDs are
                // already used by LibraryService and let us recover catalog topics.
                records = try await supabase.from("user_book")
                    .select("id:book_id, books(open_library_work_id)")
                    .eq("user_id", value: books[0].userId)
                    .is("deleted_at", value: nil)
                    .in("book_id", values: missing.map(\.uuidString)).execute().value
            }
            DiscoveryDiagnostics.log("Supabase returned \(records.count) of \(missing.count) requested books. Empty arrays can indicate RLS visibility.")
            for record in records {
                try Task.checkCancellation()
                guard let book = books.first(where: { $0.bookId == record.id }) else { continue }
                let names = record.book_genres?.compactMap { $0.genres?.name } ?? []
                var genres = Set(names.compactMap(BookGenre.init(rawValue:)))
                genres.formUnion(OpenLibraryService.shared.extractGenres(from: names))
                DiscoveryDiagnostics.log("Book \(record.id): raw genres=\(names); recognized=\(genres.map(\.rawValue).sorted())")
                if genres.isEmpty, let workID = record.open_library_work_id {
                    do {
                        DiscoveryDiagnostics.log("No recognized genres; loading Open Library work \(workID)")
                        let work = try await OpenLibraryService.shared.getWorkDetails(workId: workID)
                        genres.formUnion(OpenLibraryService.shared.extractGenres(from: work.subjects ?? []))
                        DiscoveryDiagnostics.log("Work topics: \(work.subjects?.count ?? 0); mapped genres=\(genres.map(\.rawValue).sorted())")
                    } catch {
                        DiscoveryDiagnostics.log("Work fallback failed: \(String(reflecting: error))")
                        try Task.checkCancellation()
                    }
                }
                cached[record.id] = DiscoveryLibraryEntry(workID: record.open_library_work_id,
                    title: book.book.title, genres: Array(genres))
            }
        }
        return Dictionary(grouping: books, by: \.bookId).values.compactMap { entries in
            guard let book = entries.first else { return nil }
            return cached[book.bookId] ?? DiscoveryLibraryEntry(workID: nil, title: book.book.title, genres: [])
        }
    }
}
