//
//  EmptySearchResultsView.swift
//  Hilo
//
//  Created by Cactu on 11-10-26.
//

import SwiftUI

struct EmptySearchResultsView: View {
    let searchText: String

    var body: some View {
        ContentUnavailableView {
            Label {
                Text("search_no_results_title")
            } icon: {
                Image(systemName: "books.vertical")
                    .foregroundStyle(AppColors.primaryStrong)
            }
        } description: {
            Text(
                String(
                    format: String(localized: "search_no_results_description"),
                    searchText
                )
            )
        }
    }
}

