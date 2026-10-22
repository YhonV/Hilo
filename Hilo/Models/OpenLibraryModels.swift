//
//  OpenLibraryModels.swift
//  Hilo
//
//  Created by Cactu on 08-10-26.
//
import Foundation

struct OpenLibrarySearchResponse: Decodable {
    let numFound: Int
    let docs: [OpenLibraryBookDTO]
}

struct OpenLibraryBookDTO: Decodable {
    let key: String
    let title: String
    let authorName: [String]?
    let coverId: Int?
    let firstPublishYear: Int?
    let languages: [String]?
    let editionKeys: [String]?
    let isbns: [String]?
    let publishers: [String]?
    let numberOfPagesMedian: Int?
    let editions: OpenLibrarySearchEditionsResponse?
    let subjects: [String]?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authorName = "author_name"
        case coverId = "cover_i"
        case firstPublishYear = "first_publish_year"
        case languages = "language"
        case editionKeys = "edition_key"
        case isbns = "isbn"
        case publishers = "publisher"
        case numberOfPagesMedian = "number_of_pages_median"
        case editions
        case subjects = "subjects"
    }
}

struct OpenLibrarySearchEditionsResponse: Decodable {
    let docs: [OpenLibrarySearchEditionDTO]
}

struct OpenLibrarySearchEditionDTO: Decodable {
    let key: String
    let title: String
    let coverId: Int?
    let languages: [String]?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case coverId = "cover_i"
        case languages = "language"
    }
}

struct OpenLibraryEditionsResponse: Decodable {
    let entries: [OpenLibraryEditionDTO]
}

struct OpenLibraryEditionDTO: Decodable {
    let key: String
    let title: String
    let covers: [Int]?
    let languages: [OpenLibraryLanguageDTO]?
    let isbn10: [String]?
    let isbn13: [String]?
    let publishers: [String]?
    let numberOfPages: Int?
    let publishDate: String?
    var persistedCoverURL: String? = nil

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case covers
        case languages
        case isbn10 = "isbn_10"
        case isbn13 = "isbn_13"
        case publishers
        case numberOfPages = "number_of_pages"
        case publishDate = "publish_date"
    }
}

// Presentation helpers do not change edition identity or persisted records.
extension OpenLibraryEditionDTO {
    var displayCoverURL: URL? {
        if let value = persistedCoverURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           let url = URL(string: value), ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
           url.host != nil {
            return url
        }
        return covers?.first(where: { $0 > 0 }).flatMap {
            URL(string: "https://covers.openlibrary.org/b/id/\($0)-M.jpg")
        }
    }

    var coverIdentity: String? {
        guard let url = displayCoverURL else { return nil }
        // Open Library size suffixes refer to the same image, not different covers.
        if url.host?.lowercased() == "covers.openlibrary.org" {
            return url.path.lowercased()
                .replacingOccurrences(of: #"-[sml]\.jpg$"#, with: ".jpg", options: .regularExpression)
        }
        return url.absoluteString
    }

    var languageCodes: [String] {
        (languages ?? []).map {
            $0.key.replacingOccurrences(of: "/languages/", with: "").lowercased()
        }.filter { !$0.isEmpty && $0 != "unknown" && $0 != "und" }
    }

    func matchesLanguage(_ code: String) -> Bool {
        languageCodes.contains {
            Locale.Language(identifier: $0).languageCode?.identifier(.alpha3)
                == Locale.Language(identifier: code).languageCode?.identifier(.alpha3)
        }
    }

    var languageLabel: String {
        let names = languageCodes.map { Locale.current.localizedString(forLanguageCode: $0) ?? $0.uppercased() }
        return names.isEmpty ? String(localized: "book_unknown_language") : names.joined(separator: ", ")
    }

    var publisherLabel: String {
        publishers?.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            ?? String(localized: "book_unknown_publisher")
    }

    var publicationYear: String? {
        guard let date = publishDate,
              let range = date.range(of: #"\b[12][0-9]{3}\b"#, options: .regularExpression) else { return nil }
        return String(date[range])
    }

    var metadataScore: Int {
        [!languageCodes.isEmpty,
         publishers?.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) == true,
         publicationYear != nil,
         (numberOfPages ?? 0) > 0,
         ((isbn13 ?? []) + (isbn10 ?? [])).contains(where: { !$0.isEmpty })]
            .filter { $0 }.count
    }
}

struct OpenLibraryLanguageDTO: Decodable {
    let key: String
}

struct OpenLibraryWorkDTO: Decodable {
    let description: OpenLibraryDescription?
    let subjects: [String]?
}

enum OpenLibraryDescription: Decodable {

    case text(String)

    var value: String {
        switch self {
        case .text(let value):
            return value
        }
    }

    init(from decoder: Decoder) throws {

        let container = try decoder.singleValueContainer()

        // A veces viene directamente como String
        if let string = try? container.decode(String.self) {
            self = .text(string)
            return
        }

        // Otras veces viene como { "type": "...", "value": "..." }
        let object = try container.decode(OpenLibraryDescriptionObject.self)

        self = .text(object.value)
    }
}

struct OpenLibraryDescriptionObject: Decodable {
    let value: String
}
