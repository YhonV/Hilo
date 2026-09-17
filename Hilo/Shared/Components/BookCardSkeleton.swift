//
//  BookCardSkeleton.swift
//  Hilo
//
//  Created by Cactu on 29-08-26.
//
import SwiftUI

struct BookCardSkeleton: View {

    var body: some View {

        HStack(alignment: .top, spacing: 14) {

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 75, height: 110)

            VStack(alignment: .leading, spacing: 6) {

                // Título
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 16)

                // Autor
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 13)
                    .padding(.top, 2)

                // Rating
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 70, height: 12)
                    .padding(.top, 4)

                Spacer()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
#Preview {
    BookCardSkeleton()
}
