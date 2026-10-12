//
//  BookGenre.swift
//  Hilo
//
//  Created by Cactu on 09-10-26.
//

import Foundation
import SwiftUI

enum BookGenre: String, Codable, Hashable, CaseIterable {
    
    var searchTerm: String {
        switch self {
        case .scienceFiction: "science fiction"
        case .historicalFiction: "historical fiction"
        case .youngAdult: "young adult"
        default: rawValue
        }
    }

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

extension BookGenre {

    var icon: String {
        switch self {
        case .horror: "moon.stars.fill"
        case .thriller: "eye.fill"
        case .scienceFiction: "sparkles"
        case .fantasy: "wand.and.stars"
        case .romance: "heart.fill"
        case .mystery: "magnifyingglass"
        case .crime: "person.crop.circle.badge.questionmark"
        case .dystopia: "building.2.fill"
        case .adventure: "safari.fill"
        case .historicalFiction: "books.vertical.fill"
        case .youngAdult: "book.closed.fill"
        }
    }

    var color: Color {
        switch self {
        case .horror: Color(red: 0.48, green: 0.32, blue: 0.38)
        case .thriller: Color(red: 0.57, green: 0.36, blue: 0.28)
        case .scienceFiction: Color(red: 0.34, green: 0.46, blue: 0.55)
        case .fantasy: Color(red: 0.49, green: 0.40, blue: 0.61)
        case .romance: Color(red: 0.73, green: 0.43, blue: 0.48)
        case .mystery: Color(red: 0.45, green: 0.49, blue: 0.38)
        case .crime: Color(red: 0.50, green: 0.40, blue: 0.35)
        case .dystopia: Color(red: 0.44, green: 0.47, blue: 0.48)
        case .adventure: Color(red: 0.66, green: 0.46, blue: 0.24)
        case .historicalFiction: Color(red: 0.60, green: 0.45, blue: 0.31)
        case .youngAdult: Color(red: 0.40, green: 0.52, blue: 0.43)
        }
    }
}
