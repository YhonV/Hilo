//
//  BookCoverView.swift
//  Hilo
//
//  Created by Cactu on 12-10-26.
//

import SwiftUI
import NukeUI

struct BookCoverView: View {
    let url: String

    var width: CGFloat = 85
    var height: CGFloat = 120
    private var optimizedURL: URL? {
        let coverURL = url.replacingOccurrences(
            of: "-L.jpg",
            with: "-M.jpg"
        )

        return URL(string: coverURL)
    }

    var body: some View {
        LazyImage(url: optimizedURL) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFill()
            } else if state.error != nil || url.isEmpty {
                Image("no-cover")
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

