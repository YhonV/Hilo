//
//  CalendarService.swift
//  Hilo
//
//  Created by Cactu on 02-10-26.
//
import Supabase
import Foundation


final class CalendarService {

    static let shared = CalendarService()

    init() {}

    /// Reuses the authenticated calendar RPC; quotes are not reading activity.
    func getLastReadingActivity() async throws -> Date? {
        let activities = try await getCalendarActivities(
            startDate: Date(timeIntervalSince1970: 0), endDate: Date()
        )
        return activities.filter { $0.activityType != .quote }.map(\.date).max()
    }

    /// Sum the authoritative per-day deltas, including negative page corrections.
    /// Retain contributions from books later removed from the library.
    func getWeeklyReadPages(startDate: Date, endDate: Date) async throws -> Int {
        guard let userID = supabase.auth.currentUser?.id else {
            throw URLError(.userAuthenticationRequired)
        }
        struct ReadingLogPages: Decodable {
            let pagesRead: Int
            enum CodingKeys: String, CodingKey { case pagesRead = "pages_read" }
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        var total = 0
        var offset = 0
        let pageSize = 1000
        while true {
            let rows: [ReadingLogPages] = try await supabase
                .from("reading_logs")
                .select("pages_read, user_book!inner(user_id)")
                .eq("user_book.user_id", value: userID.uuidString)
                .gte("log_date", value: formatter.string(from: startDate))
                .lt("log_date", value: formatter.string(from: endDate))
                .order("log_date")
                .order("user_book_id")
                .order("start_page")
                .order("end_page")
                .order("pages_read")
                .range(from: offset, to: offset + pageSize - 1)
                .execute()
                .value
            total += rows.reduce(0) { $0 + $1.pagesRead }
            if rows.count < pageSize { break }
            offset += pageSize
        }
        return max(0, total)
    }

    //MARK: - Obtener actividad del calendario
    func getCalendarActivities(startDate: Date, endDate: Date) async throws -> [CalendarActivity] {

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"

        let params = GetCalendarActivitiesParams(
            startDate: formatter.string(from: startDate),
            endDate: formatter.string(from: endDate)
        )

        let activities: [CalendarActivity] = try await supabase
            .rpc("get_calendar_activities", params: params)
            .execute()
            .value
        return activities
    }
}
