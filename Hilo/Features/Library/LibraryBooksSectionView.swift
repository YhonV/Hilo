//
//  LibraryBooksSectionView.swift
//  Hilo
//
//  Created by Cactu on 17-09-26.
//

import SwiftUI

enum Status: String, CaseIterable {
    case reading
    case toRead
    case read

    var localizedTitle: String {
        switch self {
        case .reading: return String(localized: "reading")
        case .toRead: return String(localized: "to_read")
        case .read: return String(localized: "books_read")
        }
    }

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
            Picker(String(localized: "reading_status_title"), selection: $selectedStatus) {
                ForEach(Status.allCases, id: \.self) { status in
                    Text(status.localizedTitle)
                        .tag(status)
                }
            }
            .pickerStyle(.segmented)

            LibraryBooksCarouselView(userLibraryBooks: filteredBooks)
        }
    }
}
