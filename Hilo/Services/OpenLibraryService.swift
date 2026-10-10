import Foundation

final class OpenLibraryService {

    static let shared = OpenLibraryService()

    private init() {}

    private let baseURL = "https://openlibrary.org/search.json"
    
    // MARK: - Aplicar mejor edición a un Book
    func enrichBookWithBestEdition(book: Book, query: String) async throws -> Book {

        guard let edition = try await getBestEdition(
            workId: book.externalId,
            query: query,
            authors: book.authors
        ) else {
            return book
        }

        var enrichedBook = book

        enrichedBook.title = edition.title

        if let coverId = edition.covers?.first {
            enrichedBook.cover = "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
        }

        enrichedBook.isbn =
            edition.isbn13?.first
            ?? edition.isbn10?.first
            ?? book.isbn

        enrichedBook.editorial =
            edition.publishers?.first
            ?? book.editorial

        enrichedBook.numberOfPages =
            edition.numberOfPages
            ?? book.numberOfPages

        enrichedBook.publishedDate =
            edition.publishDate
            ?? book.publishedDate

        if let languageKey = edition.languages?.first?.key {
            enrichedBook.language = languageKey
                .replacingOccurrences(
                    of: "/languages/",
                    with: ""
                )
        } else {
            enrichedBook.language = ""
        }

        return enrichedBook
    }

    // MARK: - Buscar libros
    func searchBooks(query: String) async throws -> [Book] {

        let cleanQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanQuery.isEmpty else {
            return []
        }

        var components = URLComponents(string: baseURL)

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "20"),

            URLQueryItem(
                name: "fields",
                value: """
                key,title,author_name,cover_i,first_publish_year,\
                language,edition_key,isbn,publisher,number_of_pages_median,\
                editions,editions.key,editions.title,editions.cover_i,editions.language
                """
            )
        ]

        // Open Library exige mínimo 3 caracteres para q=
        if cleanQuery.count < 3 {
            queryItems.append(
                URLQueryItem(
                    name: "title",
                    value: cleanQuery
                )
            )
        } else {
            queryItems.append(
                URLQueryItem(
                    name: "q",
                    value: cleanQuery
                )
            )
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        request.setValue(
            "Hilo/1.0",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "OpenLibrary",
                code: httpResponse.statusCode
            )
        }

        let searchResponse = try JSONDecoder().decode(
            OpenLibrarySearchResponse.self,
            from: data
        )

        return searchResponse.docs.map {
            mapToBook($0, query: cleanQuery)
        }
    }

    // MARK: - Obtener todas las ediciones de una obra
    func getEditions(workId: String) async throws -> [OpenLibraryEditionDTO] {

        let cleanWorkId = workId.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanWorkId.isEmpty else {
            return []
        }

        let workPath: String

        if cleanWorkId.hasPrefix("/works/") {
            workPath = cleanWorkId
        } else {
            workPath = "/works/\(cleanWorkId)"
        }

        guard var components = URLComponents(
            string: "https://openlibrary.org\(workPath)/editions.json"
        ) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "limit", value: "100")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        request.setValue(
            "Hilo/1.0",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "OpenLibrary",
                code: httpResponse.statusCode
            )
        }

        let editionsResponse = try JSONDecoder().decode(
            OpenLibraryEditionsResponse.self,
            from: data
        )

        return editionsResponse.entries
    }

    // MARK: - Obtener mejor edición
    func getBestEdition(
        workId: String,
        query: String,
        authors: [String]
    ) async throws -> OpenLibraryEditionDTO? {

        let editions = try await getEditions(
            workId: workId
        )

        return selectBestEdition(
            from: editions,
            query: query,
            authors: authors
        )
    }

    // MARK: - Seleccionar mejor edición
    private func selectBestEdition(from editions: [OpenLibraryEditionDTO], query: String, authors: [String]) -> OpenLibraryEditionDTO? {

        let cleanQuery = removeAuthors(
            from: query,
            authors: authors
        )

        for edition in editions {

            let score = titleMatchScore(
                title: edition.title,
                query: cleanQuery
            )
        }

        return editions.max { first, second in

            let firstScore = titleMatchScore(
                title: first.title,
                query: cleanQuery
            )

            let secondScore = titleMatchScore(
                title: second.title,
                query: cleanQuery
            )

            return firstScore < secondScore
        }
    }

    // MARK: - Quitar nombre del autor de la búsqueda
    private func removeAuthors(
        from query: String,
        authors: [String]
    ) -> String {

        var queryWords = normalize(query)
            .split(separator: " ")
            .map(String.init)

        let authorWords = Set(
            authors.flatMap {
                normalize($0)
                    .split(separator: " ")
                    .map(String.init)
            }
        )

        queryWords.removeAll {
            authorWords.contains($0)
        }

        return queryWords.joined(separator: " ")
    }

    // MARK: - Score de similitud de título
    private func titleMatchScore(
        title: String,
        query: String
    ) -> Int {

        let normalizedTitle = normalize(title)
        let normalizedQuery = normalize(query)

        guard !normalizedQuery.isEmpty else {
            return 0
        }

        // Coincidencia exacta
        if normalizedTitle == normalizedQuery {
            return 100
        }

        // Ejemplo:
        // query = "the stranger"
        // title = "the stranger novel"
        if normalizedTitle.hasPrefix(normalizedQuery) {
            return 90
        }

        if normalizedTitle.contains(normalizedQuery) {
            return 80
        }

        let titleWords = Set(
            normalizedTitle.split(separator: " ")
        )

        let queryWords = Set(
            normalizedQuery.split(separator: " ")
        )

        guard !queryWords.isEmpty else {
            return 0
        }

        let matches = titleWords.intersection(queryWords)

        return Int(
            Double(matches.count)
            / Double(queryWords.count)
            * 70
        )
    }

    // MARK: - Normalizar texto
    private func normalize(
        _ text: String
    ) -> String {

        text
            .lowercased()
            .folding(
                options: .diacriticInsensitive,
                locale: .current
            )
            .components(separatedBy: .punctuationCharacters)
            .joined(separator: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    // MARK: - Convertir resultado de búsqueda a Book
    private func mapToBook(
        _ dto: OpenLibraryBookDTO,
        query: String
    ) -> Book {

        let preferredEdition = dto.editions?.docs.first

        let workScore = titleMatchScore(
            title: dto.title,
            query: query
        )

        let editionScore = preferredEdition.map {
            titleMatchScore(
                title: $0.title,
                query: query
            )
        } ?? 0

        let useEdition = editionScore > workScore

        let title: String
        let coverId: Int?

        if useEdition, let edition = preferredEdition {

            title = edition.title
            coverId = edition.coverId ?? dto.coverId

        } else {

            title = dto.title
            coverId = dto.coverId
        }

        let cover: String

        if let coverId {
            cover = "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
        } else {
            cover = ""
        }

        let isbn =
            dto.isbns?.first(where: { $0.count == 13 })
            ?? dto.isbns?.first

        let language: String

        if dto.languages?.contains("spa") == true {
            language = "spa"
        } else {
            language = dto.languages?.first ?? "unknown"
        }

        return Book(
            externalId: dto.key,
            title: title,
            authors: dto.authorName ?? [],
            cover: cover,
            genre: [],
            description: nil,
            publishedDate: dto.firstPublishYear.map(String.init),
            numberOfPages: dto.numberOfPagesMedian,
            isbn: isbn,
            averageRating: nil,
            totalReviews: 0,
            editorial: dto.publishers?.first
                ?? "Editorial desconocida",
            language: language
        )
    }
    
    // MARK: - Obtener detalle de una obra
    func getWorkDetails(
        workId: String
    ) async throws -> OpenLibraryWorkDTO {

        let cleanWorkId = workId.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanWorkId.isEmpty else {
            throw URLError(.badURL)
        }

        let workPath: String

        if cleanWorkId.hasPrefix("/works/") {
            workPath = cleanWorkId
        } else {
            workPath = "/works/\(cleanWorkId)"
        }

        guard let url = URL(
            string: "https://openlibrary.org\(workPath).json"
        ) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        request.setValue(
            "Hilo/1.0",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "OpenLibrary",
                code: httpResponse.statusCode
            )
        }

        return try JSONDecoder().decode(
            OpenLibraryWorkDTO.self,
            from: data
        )
    }
    
    // MARK: - Obtener sinopsis
    func getDescription(
        workId: String
    ) async throws -> String? {

        let work = try await getWorkDetails(
            workId: workId
        )

        let description = work.description?.value
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let description,
              !description.isEmpty else {
            return nil
        }

        return description
    }
    
    // MARK: - Convertir subjects en géneros
    func extractGenres(
        from subjects: [String]
    ) -> [BookGenre] {

        let normalizedSubjects = subjects.map {
            normalize($0)
        }

        let genreRules: [(keywords: [String], genre: BookGenre)] = [
            (
                ["horror", "terror", "horror fiction", "horror stories"],
                .horror
            ),
            (
                ["thriller", "thrillers", "suspense"],
                .thriller
            ),
            (
                ["science fiction", "ciencia ficcion", "sci fi"],
                .scienceFiction
            ),
            (
                ["fantasy", "fantasia"],
                .fantasy
            ),
            (
                ["romance", "romantic fiction"],
                .romance
            ),
            (
                ["mystery", "mysteries"],
                .mystery
            ),
            (
                ["crime", "detective"],
                .crime
            ),
            (
                ["dystopia", "dystopian", "distopia"],
                .dystopia
            ),
            (
                ["adventure", "aventura"],
                .adventure
            ),
            (
                ["historical fiction", "ficcion historica"],
                .historicalFiction
            ),
            (
                ["young adult", "juvenile fiction"],
                .youngAdult
            )
        ]

        var result: [BookGenre] = []

        for rule in genreRules {

            let matches = normalizedSubjects.contains { subject in
                rule.keywords.contains { keyword in
                    subject.contains(keyword)
                }
            }

            if matches && !result.contains(rule.genre) {
                result.append(rule.genre)
            }
        }

        return Array(result.prefix(3))
    }
}
