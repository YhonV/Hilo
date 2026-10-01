//
//  Follow.swift
//  Hilo
//
//  Created by Yhon Vivas on 05-03-26.
//

import Foundation
import FirebaseFirestore

struct Follow: Codable, Identifiable {
    @DocumentID var id: String?
    var createdAt: Date
}
