//
//  EditQuoteSheetView.swift
//  Hilo
//
//  Created by Cactu on 27-09-26.
//

import SwiftUI

struct EditQuoteSheetView: View {
    let quote: Quote
    let totalPages: Int?

    @State private var quoteText: String
    @State private var pageText: String

    @State private var isSaving = false
    @State private var validationMessage: String?
    @State private var saveErrorMessage: String?
    @State private var showSaveError = false

    @Environment(\.dismiss) private var dismiss
    @Environment(QuoteViewModel.self) private var quoteViewModel

    init(quote: Quote, totalPages: Int?) {
        self.quote = quote
        self.totalPages = totalPages

        _quoteText = State(initialValue: quote.content)
        _pageText = State(
            initialValue: quote.pageNumber.map(String.init) ?? ""
        )
    }

    var body: some View {
        QuoteComposerView(
            quoteText: $quoteText,
            pageText: $pageText,
            validationMessage: $validationMessage,
            isSaving: isSaving,
            onSave: {
                Task {
                    do {
                        try await updateQuote()
                    } catch {
                        saveErrorMessage =
                            "No se pudo actualizar la cita. Inténtalo nuevamente."

                        showSaveError = true
                    }
                }
            },
            onCamera: {
                // En edición no necesitamos OCR por ahora
            }
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .alert(
            "No se pudo actualizar",
            isPresented: $showSaveError
        ) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(
                saveErrorMessage
                ?? "Ocurrió un error inesperado."
            )
        }
    }

    private func updateQuote() async throws {
        guard let input = checkInput() else {
            return
        }

        isSaving = true
        defer {
            isSaving = false
        }

        try await quoteViewModel.updateQuote(
            quoteId: quote.id,
            content: input.content,
            pageNumber: input.pageNumber
        )

        dismiss()
    }

    private func checkInput()
        -> (content: String, pageNumber: Int?)? {

        validationMessage = nil

        let content = quoteText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let page = pageText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !content.isEmpty else {
            return nil
        }

        if page.isEmpty {
            return (
                content: content,
                pageNumber: nil
            )
        }

        guard let pageNumber = Int(page),
              pageNumber > 0 else {
            validationMessage =
                "Ingresa un número de página válido."

            return nil
        }

        if let totalPages,
           pageNumber > totalPages {

            validationMessage =
                "Este libro tiene \(totalPages) páginas."

            return nil
        }

        return (
            content: content,
            pageNumber: pageNumber
        )
    }
}
