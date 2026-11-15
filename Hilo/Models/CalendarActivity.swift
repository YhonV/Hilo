//
//  CalendarAcitivity.swift
//  Hilo
//
//  Created by Cactu on 02-10-26.
//
import SwiftUI
import Foundation

struct CalendarActivity: Decodable {
    var date: Date
    var userBookId: UUID
    var book: CalendarBook
    var activityType: ActivityType
    var activityContent: String

    enum CodingKeys: String, CodingKey {
        case date
        case userBookId = "user_book_id"
        case book
        case activityType = "activity_type"
        case activityContent = "activity_content"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let dateString = try container.decode(String.self, forKey: .date)

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        guard let parsedDate = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .date,
                in: container,
                debugDescription: "Fecha inválida: \(dateString)"
            )
        }

        date = parsedDate
        userBookId = try container.decode(UUID.self, forKey: .userBookId)
        book = try container.decode(CalendarBook.self, forKey: .book)
        activityType = try container.decode(ActivityType.self, forKey: .activityType)
        activityContent = try container.decode(String.self, forKey: .activityContent)
    }
}

enum ActivityType: String, Decodable {
    case started
    case progress
    case finished
    case quote
}

struct CalendarBook: Decodable {
    var bookId: UUID
    var title: String
    var cover: String?

    enum CodingKeys: String, CodingKey {
        case bookId = "book_id"
        case title
        case cover = "cover_url"
    }
}


struct GetCalendarActivitiesParams: Encodable {
    let startDate: String
    let endDate: String

    enum CodingKeys: String, CodingKey {
        case startDate = "p_start_date"
        case endDate = "p_end_date"
    }
}
