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
        language: String
    ) async throws -> String? {

        var components = URLComponents(string: BASE_URL)

        components?.queryItems = [
            URLQueryItem(
                name: "q",
                value: "intitle:\(title)"
            ),
            URLQueryItem(
                name: "key",
                value: API_KEY
            ),
            URLQueryItem(
                name: "maxResults",
                value: "20"
            )
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

        let match = response.items?.first { item in

            let info = item.volumeInfo

            guard
                let googleTitle = info.title,
                let description = info.description,
                !description.isEmpty
            else {
                return false
            }

            let titleMatches =
                normalize(googleTitle) == expectedTitle

            let authorMatches = info.authors?.contains { googleAuthor in
                expectedAuthors.contains {
                    normalize(googleAuthor).contains($0)
                    || $0.contains(normalize(googleAuthor))
                }
            } ?? false

            let languageMatches =
                info.language == expectedLanguage

            return titleMatches
                && authorMatches
                && languageMatches
        }

        return match?.volumeInfo.description
    }
    
    private func googleLanguageCode(from openLibraryCode: String) -> String {

        switch openLibraryCode {
        case "spa":
            return "es"

        case "eng":
            return "en"

        case "fre":
            return "fr"

        case "ger":
            return "de"

        case "ita":
            return "it"

        case "por":
            return "pt"

        default:
            return openLibraryCode
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
