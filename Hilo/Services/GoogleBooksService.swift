//
//  GoogleBooksService.swift
//  Hilo
//
//  Created by Yhon Vivas on 08-03-26.
//
import Foundation

final class GoogleBooksService {
    
    static let shared = GoogleBooksService()
    
    private init() {}
    
    private let BASE_URL = "https://www.googleapis.com/books/v1/volumes"
    
    private let API_KEY =
    Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String ?? ""
    
    
    func getDescription(
        title: String,
        authors: [String],
        language: String,
        allowAlternativeSearch: Bool = true
    ) async throws -> String? {

        var components = URLComponents(string: BASE_URL)

        let query = allowAlternativeSearch
            ? title
            : "\(title) \(authors.joined(separator: " "))"

        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: API_KEY),
            URLQueryItem(name: "maxResults", value: "20")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, urlResponse) = try await URLSession.shared.data(from: url)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "GoogleBooks",
                code: httpResponse.statusCode
            )
        }

        let response = try JSONDecoder().decode(
            GoogleBooksMetadataResponse.self,
            from: data
        )

        let expectedTitle = normalize(title)

        let expectedAuthors = authors.map {
            normalize($0)
        }

        let expectedLanguage = googleLanguageCode(from: language)

        var alternativeTitle: String?
        var candidates: [GoogleBooksMetadataItem] = []

        let items = response.items ?? []

        for item in items {

            let info = item.volumeInfo

            guard let googleTitle = info.title else {
                continue
            }

            let normalizedGoogleTitle = normalize(googleTitle)

            let authorMatches = info.authors?.contains { googleAuthor in
                expectedAuthors.contains {
                    normalize(googleAuthor).contains($0)
                    || $0.contains(normalize(googleAuthor))
                }
            } ?? false

            if authorMatches,
               normalizedGoogleTitle != expectedTitle,
               expectedTitle.contains(normalizedGoogleTitle),
               alternativeTitle == nil {

                alternativeTitle = googleTitle
            }

            let titleMatches =
                normalizedGoogleTitle == expectedTitle

            guard
                titleMatches,
                authorMatches,
                let description = info.description,
                !description.isEmpty
            else {
                continue
            }

            candidates.append(item)
        }

        let match: GoogleBooksMetadataItem?

        if let expectedLanguage {
            match = candidates.first {
                $0.volumeInfo.language == expectedLanguage
            }
        } else {
            match = candidates.first {
                $0.volumeInfo.language == "es"
                || $0.volumeInfo.language == "en"
            }
        }

        if let description = match?.volumeInfo.description {
            return description
        }

        if allowAlternativeSearch,
           let alternativeTitle {

            return try await getDescription(
                title: alternativeTitle,
                authors: authors,
                language: language,
                allowAlternativeSearch: false
            )
        }

        return nil
    }
    
    private func googleLanguageCode(from language: String) -> String? {
        switch language {
        case "spa", "es":
            return "es"

        case "eng", "en":
            return "en"

        default:
            return nil
        }
    }
    
    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}
