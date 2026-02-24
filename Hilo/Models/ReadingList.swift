//
//  ReadingList.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import Foundation

enum States: String {
    case read = "Leído"
    case reading = "Leyendo"
    case toRead = "Por leer"
}

struct ReadingList {
    var readingListId: String
    var userId: String
    var bookId: String
    var states: States
    var dateOfBegining: Date?
    var dateOfFinish: Date?
}
