//
//  ReadingList.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import Foundation
import FirebaseFirestore

enum ReadingStatus: String, Codable {
    case read = "read"
    case reading = "reading"
    case toRead = "to_read"
}

struct ReadingList: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var bookId: String
    var states: ReadingStatus
    var dateOfBegining: Date?
    var dateOfFinish: Date?
}
