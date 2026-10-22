//
//  RecentSearchesView.swift
//  Hilo
//
//  Created by Cactu on 12-10-26.
//

import SwiftUI

struct RecentSearchesView: View {
    let searches: [String]
    let onSearchSelected: (String) -> Void
    let onClearHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("search_recent_title")
                    .font(.headline)

                Spacer()

                Button("search_clear_history") {
                    onClearHistory()
                }
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryStrong)
            }

            VStack(spacing: 0) {
                ForEach(searches, id: \.self) { search in
                    Button {
                        onSearchSelected(search)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.secondary)

                            Text(search)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "arrow.up.left")
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if search != searches.last {
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

