//
//  BookGenre.swift
//  Hilo
//
//  Created by Cactu on 09-10-26.
//

import Foundation

enum BookGenre: String, Codable, Hashable {
    case horror
    case thriller
    case scienceFiction
    case fantasy
    case romance
    case mystery
    case crime
    case dystopia
    case adventure
    case historicalFiction
    case youngAdult

    var localizedName: String {
        switch self {
        case .horror:
            String(localized: "genre_horror")

        case .thriller:
            String(localized: "genre_thriller")

        case .scienceFiction:
            String(localized: "genre_science_fiction")

        case .fantasy:
            String(localized: "genre_fantasy")

        case .romance:
            String(localized: "genre_romance")

        case .mystery:
            String(localized: "genre_mystery")

        case .crime:
            String(localized: "genre_crime")

        case .dystopia:
            String(localized: "genre_dystopia")

        case .adventure:
            String(localized: "genre_adventure")

        case .historicalFiction:
            String(localized: "genre_historical_fiction")

        case .youngAdult:
            String(localized: "genre_young_adult")
        }
    }
}
