//
//  AdditionalSearchResultsSkeletonView.swift
//  Hilo
//
//  Created by Cactu on 11-10-26.
//

import SwiftUI

struct AdditionalSearchResultsSkeletonView: View {

    private let skeletonColor = Color.gray.opacity(0.3)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 10) {
                Image(systemName: "books.vertical")
                    .foregroundStyle(AppColors.primaryStrong)

                Text("search_explore_more")
                    .font(.headline)
            }

            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 170, height: 14)

                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 75, height: 14)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColors.primaryStrong.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

#Preview {
    AdditionalSearchResultsSkeletonView()
        .padding()
}

