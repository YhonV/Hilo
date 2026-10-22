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
    var bookTitle: String? = nil
    var bookCoverURL: String? = nil

    private var sourceTitle: String {
        let title = bookTitle ?? quote.bookContext?.book?.title
        return title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? title! : String(localized: "quote_unknown_book")
    }

    private var sourceCoverURL: URL? {
        guard let value = bookCoverURL ?? quote.bookContext?.edition?.coverURL,
              !value.isEmpty else { return nil }
        return URL(string: value)
    }
    
    @State private var confirmationDelete: Bool = false
    @State private var showEditQuote = false
    
    @Environment(QuoteViewModel.self) private var quoteViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundStyle(AppColors.accent)
                    .accessibilityHidden(true)

                Text(quote.content)
                    .font(.body)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(AppColors.titles)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

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
            
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 8) {
                    AsyncImage(url: sourceCoverURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.border.opacity(0.3))
                                .overlay {
                                    Image(systemName: "book.closed")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.secondaryText)
                                }
                        }
                    }
                    .frame(width: 28, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .accessibilityHidden(true)

                    Text(sourceTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.titles)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    if let pageNumber = quote.pageNumber {
                        Text(String(format: String(localized: "reading_page_number"), pageNumber))
                    }
                    if !formattedDate.isEmpty {
                        Text(formattedDate)
                    }
                }
                .font(.caption2)
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
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

        let fractionalDate = inputFormatter.date(from: quote.createdAt)
        inputFormatter.formatOptions = [.withInternetDateTime]
        guard let date = fractionalDate ?? inputFormatter.date(from: quote.createdAt) else {
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
