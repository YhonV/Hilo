//
//  SearchHistoryService.swift
//  Hilo
//
//  Created by Cactu on 12-10-26.
//

import Foundation

final class SearchHistoryService {

    static let shared = SearchHistoryService()

    private let storageKey = "recent_book_searches"
    private let maxSearches = 3

    private init() {}

    func getRecentSearches() -> [String] {
        UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }

    func saveSearch(_ query: String) {
        let cleanQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanQuery.isEmpty else { return }

        var searches = getRecentSearches()

        searches.removeAll {
            $0.compare(
                cleanQuery,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) == .orderedSame
        }

        searches.insert(cleanQuery, at: 0)

        UserDefaults.standard.set(
            Array(searches.prefix(maxSearches)),
            forKey: storageKey
        )
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

