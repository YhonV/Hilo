//
//  QuotesCard.swift
//  Hilo
//
//  Created by Cactu on 05-09-26.
//

import SwiftUI

struct QuoteCard: View {

    let quote: String
    let bookTitle: String
    let author: String
    let page: String?

    var body: some View {
        
        VStack(alignment: .leading, spacing: 14) {
            
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundStyle(AppColors.accent.opacity(0.5))
            
            Text(quote)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            
            HStack(alignment: .center, spacing: 10) {
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.background)
                    .frame(width: 40, height: 52)
                
                VStack(alignment: .leading, spacing: 3) {
                    
                    Text(bookTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(author)
                        .font(.footnote)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 12)
                
                if let page {
                    Text("pág. \(page)")
                        .font(.footnote)
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize()
                }
            }
        }
        .padding(18)
        .frame(width: 300, alignment: .leading)
        .frame(minHeight: 155, alignment: .topLeading)
        .background(AppColors.surface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    AppColors.border.opacity(0.25),
                    lineWidth: 1
                )
        }
    }
}
