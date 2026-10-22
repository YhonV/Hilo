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
    @State private var showsGrid = false

    let userLibraryBooks: [UserLibraryBook]

    private var filteredBooks: [UserLibraryBook] {
        userLibraryBooks.filter {
            $0.status.name == selectedStatus.databaseValue
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "library_title"))
                    .font(.headline)
                Spacer()
                if !userLibraryBooks.isEmpty {
                    Button {
                        showsGrid.toggle()
                    } label: {
                        Label(showsGrid ? String(localized: "collection_show_carousel") : String(localized: "library_show_grid"),
                              systemImage: showsGrid ? "rectangle.portrait.on.rectangle.portrait" : "square.grid.2x2")
                            .labelStyle(.iconOnly)
                            .font(.body.weight(.medium))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .controlSize(.regular)
                    .tint(AppColors.accent)
                }
            }
            .frame(minHeight: 44)

            Picker(String(localized: "reading_status_title"), selection: $selectedStatus) {
                ForEach(Status.allCases, id: \.self) { status in
                    Text(status.localizedTitle)
                        .tag(status)
                }
            }
            .pickerStyle(.segmented)

            if !filteredBooks.isEmpty {
                if showsGrid {
                    LibraryBooksGridView(books: filteredBooks)
                } else {
                    LibraryBooksCarouselView(userLibraryBooks: Array(filteredBooks.prefix(6)))
                }
            }
        }
    }
}
