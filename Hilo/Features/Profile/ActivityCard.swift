//
//  ActivityCard.swift
//  Hilo
//
//  Created by Cactu on 05-09-26.
//

import SwiftUI

struct ActivityCard: View {

    let icon: String
    let value: String
    let title: String
    let subtitle: String
    let coverImage: UIImage?

    var body: some View {

        ZStack {

            ImageGradient(
                image: coverImage,
                count: 3,
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
                overlayOpacity: 0.28,
                saturation: 0.55
            )

            VStack(spacing: 6) {

                Image(systemName: icon)
                    .foregroundStyle(.white)

                Text(value)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .fontWeight(.bold)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 155, height: 100)
        .clipShape(.rect(cornerRadius: 20))
    }
}


