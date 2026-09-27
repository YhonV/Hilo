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
    @State private var quoteText: String
    @State private var pageText: String

    @State private var isSaving: Bool = false
    
    @State private var validationMessage: String?
    @State private var saveErrorMessage: String?
    @State private var showSaveError: Bool = false
    @State private var showEditQuote = false
    
    @Environment(QuoteViewModel.self) private var quoteViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(quote: Quote, totalPages: Int?) {
        self.quote = quote
        self.totalPages = totalPages

        _quoteText = State(initialValue: quote.content)
        _pageText = State(
            initialValue: quote.pageNumber.map(String.init) ?? ""
        )
    }

    
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
                        Label("Editar", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        confirmationDelete = true
                    } label: {
                        Label("Eliminar", systemImage: "trash")
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
                        "Página \(pageNumber)",
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
        .alert("¿Eliminar esta cita?", isPresented: $confirmationDelete) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                Task {
                    do {
                        try await quoteViewModel.deleteQuote(quoteId: quote.id)
                    } catch {
                        print("error \(error)")
                    }
                }
            }
        } message: {
            Text("Esta acción no se puede deshacer.")
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
