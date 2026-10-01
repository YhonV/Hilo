//
//  BookDetailRaw.swift
//  Hilo
//
//  Created by Cactu on 01-10-26.
//
import SwiftUI

struct BookDetailRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {

            Image(systemName: systemImage)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))

                Text(value)
                    .font(.body)
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
    }
}
