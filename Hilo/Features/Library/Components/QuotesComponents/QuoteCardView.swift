//
//  QuoteCardView.swift
//  Hilo
//
//  Created by Cactu on 25-09-26.
//

import SwiftUI

struct QuoteCardView: View {
    let quote: Quote
    let totalPages: Int?
    
    @State private var confirmationDelete: Bool = false
    @State private var showEditQuote = false
    
    @Environment(QuoteViewModel.self) private var quoteViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Image(systemName: "quote.opening")
                    .font(.title2)
                    .foregroundStyle(AppColors.accent)
                
                Spacer()
                
                Menu {
                    Button {
                        showEditQuote = true
                    } label: {
                        Label(String(localized: "common_edit"), systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        confirmationDelete = true
                    } label: {
                        Label(String(localized: "common_delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundStyle(AppColors.accent)
                }
            }
            
            Text(quote.content)
                .font(.body)
                .lineLimit(3, reservesSpace: true)
                .foregroundStyle(AppColors.titles)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {

                if let pageNumber = quote.pageNumber {
                    Label(
                        String(format: String(localized: "reading_page_number"), pageNumber),
                        systemImage: "book.pages"
                    )
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            AppColors.surface,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.border.opacity(0.5), lineWidth: 1)
        }
        .alert(String(localized: "quote_delete_confirmation"), isPresented: $confirmationDelete) {
            Button(String(localized: "common_cancel"), role: .cancel) {}
            Button(String(localized: "common_delete"), role: .destructive) {
                Task {
                    do {
                        try await quoteViewModel.deleteQuote(quoteId: quote.id)
                    } catch {
                        print("error \(error)")
                    }
                }
            }
        } message: {
            Text(String(localized: "delete_irreversible"))
        }
        .sheet(isPresented: $showEditQuote) {
            EditQuoteSheetView(
                quote: quote,
                totalPages: totalPages
            )
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
        }
    }

    private var formattedDate: String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        guard let date = inputFormatter.date(from: quote.createdAt) else {
            return ""
        }

        return date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .year()
        )
    }
    
}
