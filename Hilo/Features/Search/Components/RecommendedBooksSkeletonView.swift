//
//  RecommendedBooksSkeletonView.swift
//  Hilo
//
//  Created by Cactu on 11-10-26.
//

import SwiftUI

struct RecommendedBooksSkeletonView: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(title)
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {

                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 115, height: 165)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 14)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 75, height: 12)
                        }
                        .frame(width: 115, alignment: .leading)
                    }
                }
                .padding(.horizontal)
            }
            .scrollDisabled(true)
        }
    }
}
