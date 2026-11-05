//
//  BookCoverView.swift
//  Hilo
//
//  Created by Cactu on 12-10-26.
//

import SwiftUI
import NukeUI
import Nuke

struct BookCoverView: View {
    let url: String

    var width: CGFloat = 85
    var height: CGFloat = 120

    var body: some View {
        LazyImage(request: BookCoverSource.request(url)) { state in
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

