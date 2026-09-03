//
//  BookCardSkeleton.swift
//  Hilo
//
//  Created by Cactu on 29-08-26.
//
import SwiftUI

struct BookCardSkeleton: View {
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 110, height: 160)
            .frame(width: 110, height: 160)
            .clipped()
            .cornerRadius(10)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 90, height: 16)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 12)
        }
    }
}

#Preview {
    BookCardSkeleton()
}
