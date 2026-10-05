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

    private init() {}

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
