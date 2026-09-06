//
//  ReadingCard.swift
//  Hilo
//
//  Created by Cactu on 05-09-26.
//

import SwiftUI

struct ReadingCard: View {
    @State private var sliderValue: Double = 43
    private let maxValue: Double = 100
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .frame(width: 90, height: 130)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("El resplandor")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Stephen King")
                        .font(.callout)
                        .foregroundStyle(AppColors.secondaryText)
                    
                    Text("43% leído")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                    ProgressView(value: 0.43)
                        .accentColor(AppColors.accent)
                    Text("Página 215 de 500")
                        .font(.footnote)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    ReadingCard()
}
