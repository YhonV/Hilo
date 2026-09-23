//
//  LibraryBooksSectionView.swift
//  Hilo
//
//  Created by Cactu on 17-09-26.
//

import SwiftUI

enum Status: String, CaseIterable {
    case reading = "Leyendo"
    case toRead = "Por leer"
    case read = "Leídos"

    var databaseValue: String {
        switch self {
        case .reading:
            return "reading"
        case .toRead:
            return "toRead"
        case .read:
            return "read"
        }
    }
}

struct LibraryBooksSectionView: View {

    @State private var selectedStatus = Status.reading

    let userLibraryBooks: [UserLibraryBook]

    private var filteredBooks: [UserLibraryBook] {
        userLibraryBooks.filter {
            $0.status.name == selectedStatus.databaseValue
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Estado de lectura", selection: $selectedStatus) {
                ForEach(Status.allCases, id: \.self) { status in
                    Text(status.rawValue)
                        .tag(status)
                }
            }
            .pickerStyle(.segmented)

            LibraryBooksCarouselView(userLibraryBooks: filteredBooks)
        }
    }
}
