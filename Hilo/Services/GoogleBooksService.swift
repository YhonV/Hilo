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
        Bundle.main.object(
            forInfoDictionaryKey: "GoogleBooksAPIKey"
        ) as? String ?? ""


    // MARK: - Obtener descripción

    func getDescription(
        title: String,
        authors: [String],
        language: String,
        allowAlternativeSearch: Bool = true
    ) async throws -> String? {

        var components = URLComponents(string: BASE_URL)

        // Siempre buscamos usando título + autor para reducir resultados irrelevantes.
        let query = "\(title) \(authors.joined(separator: " "))"

        components?.queryItems = [
            URLQueryItem(
                name: "q",
                value: query
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

        let (data, urlResponse) = try await URLSession.shared.data(
            from: url
        )

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

        let items = response.items ?? []

        let expectedLanguage = googleLanguageCode(
            from: language
        )

        let normalizedExpectedTitle = normalize(title)

        var alternativeTitle: String?

        var bestMatch: GoogleBooksMetadataItem?
        var bestScore = Int.min


        // MARK: Evaluar resultados

        for item in items {

            let info = item.volumeInfo

            guard let googleTitle = info.title else {
                continue
            }

            let normalizedGoogleTitle = normalize(
                googleTitle
            )


            // MARK: Detectar título alternativo

            let authorMatches = info.authors?.contains {
                googleAuthor in

                authors.contains { expectedAuthor in

                    let normalizedGoogleAuthor =
                        normalize(googleAuthor)

                    let normalizedExpectedAuthor =
                        normalize(expectedAuthor)

                    return normalizedGoogleAuthor.contains(
                        normalizedExpectedAuthor
                    )
                    ||
                    normalizedExpectedAuthor.contains(
                        normalizedGoogleAuthor
                    )
                }

            } ?? false


            /*
             Ejemplo:

             Open Library:
             "Amanecer rojo 2. Hijo dorado"

             Google:
             "Hijo dorado"

             Si pertenece al mismo autor, podemos usar
             "Hijo dorado" para una segunda búsqueda.
             */

            if authorMatches,
               normalizedGoogleTitle != normalizedExpectedTitle,
               normalizedExpectedTitle.contains(
                    normalizedGoogleTitle
               ),
               alternativeTitle == nil {

                alternativeTitle = googleTitle
            }


            // MARK: Puntuar candidato

            guard let score = metadataScore(
                info: info,
                expectedTitle: title,
                expectedAuthors: authors,
                preferredLanguage: expectedLanguage
            ) else {
                continue
            }


            if score > bestScore {
                bestScore = score
                bestMatch = item
            }
        }


        // MARK: Usar mejor resultado

        if bestScore >= 120,
           let description =
                bestMatch?.volumeInfo.description {

            return description
        }


        // MARK: Segundo intento con título alternativo

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


    // MARK: - Puntuar metadata de Google Books

    private func metadataScore(
        info: GoogleBooksMetadataVolumeInfo,
        expectedTitle: String,
        expectedAuthors: [String],
        preferredLanguage: String?
    ) -> Int? {

        guard
            let googleTitle = info.title,
            let description = info.description,
            !description
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        else {
            return nil
        }


        // Hilo solo utilizará sinopsis en español o inglés.
        if let language = info.language,
           language != "es",
           language != "en" {

            return nil
        }


        let normalizedTitle = normalize(
            googleTitle
        )

        let normalizedExpectedTitle = normalize(
            expectedTitle
        )

        var score = 0


        // MARK: Título

        if normalizedTitle == normalizedExpectedTitle {

            score += 100

        } else if
            normalizedTitle.contains(
                normalizedExpectedTitle
            )
            ||
            normalizedExpectedTitle.contains(
                normalizedTitle
            ) {

            score += 50

        } else {

            // El título no parece corresponder al libro.
            return nil
        }


        // MARK: Autor

        if let googleAuthors = info.authors,
           !googleAuthors.isEmpty {

            let authorMatches = googleAuthors.contains {
                googleAuthor in

                expectedAuthors.contains {
                    expectedAuthor in

                    let normalizedGoogleAuthor =
                        normalize(googleAuthor)

                    let normalizedExpectedAuthor =
                        normalize(expectedAuthor)

                    return normalizedGoogleAuthor.contains(
                        normalizedExpectedAuthor
                    )
                    ||
                    normalizedExpectedAuthor.contains(
                        normalizedGoogleAuthor
                    )
                }
            }


            if authorMatches {

                score += 80

            } else {

                score -= 80
            }
        }


        // MARK: Idioma

        if let preferredLanguage {

            if info.language == preferredLanguage {

                score += 30

            } else if
                info.language == "es"
                || info.language == "en" {

                score -= 10
            }
        }


        // MARK: Penalizar packs / colecciones completas

        let unwantedTerms = [
            "pack",
            "bundle",
            "box set",
            "coleccion",
            "trilogia",
            "saga"
        ]

        let isPack = unwantedTerms.contains { term in
            normalizedTitle.contains(term)
        }

        if isPack,
           normalizedTitle != normalizedExpectedTitle {

            score -= 100
        }


        return score
    }


    // MARK: - Convertir idioma Open Library -> Google

    private func googleLanguageCode(
        from language: String
    ) -> String? {

        switch language {

        case "spa", "es":
            return "es"

        case "eng", "en":
            return "en"

        default:
            return nil
        }
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
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }
}
