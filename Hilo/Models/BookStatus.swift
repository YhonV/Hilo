//
//  BookStatus.swift
//  Hilo
//
//  Created by Cactu on 06-09-26.
//

enum BookStatus: String, Codable {
    case reading
    case read
    case toRead

    var id: Int {
        switch self {
        case .reading:
            return 1
        case .read:
            return 2
        case .toRead:
            return 3
        }
    }
}
