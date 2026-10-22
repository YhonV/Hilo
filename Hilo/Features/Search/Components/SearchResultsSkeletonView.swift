//
//  SearchResultsSkeletonView.swift
//  Hilo
//
//  Created by Cactu on 11-10-26.
//

import SwiftUI

struct SearchResultsSkeletonView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .foregroundStyle(AppColors.primaryStrong)

                Text("search_best_matches")
                    .font(.headline)
            }
            .padding(.bottom, 4)

            LazyVStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { _ in
                    BookCardSkeleton()

                    Divider()
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    SearchResultsSkeletonView()
}

