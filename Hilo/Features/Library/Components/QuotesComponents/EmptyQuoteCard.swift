//
//  EmptyQuoteCard.swift
//  Hilo
//
//  Created by Cactu on 01-10-26.
//

import SwiftUI

struct EmptyQuoteCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.7))

            Text("No hay citas guardadas")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Guarda una cita de este libro para verla aquí.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
#Preview {
    EmptyQuoteCard()
}
