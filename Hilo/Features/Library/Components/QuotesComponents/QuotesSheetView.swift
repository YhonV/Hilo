//
//  QuotesSheetView.swift
//  Hilo
//
//  Created by Cactu on 24-09-26.
//
import SwiftUI
import UIKit

enum OCRFlowStep {
    case camera
    case crop
}

struct QuotesSheetView: View {
    
    // MARK: - Servicios
    private let ocrService = OCRService()

    // MARK: - Estado
    @State private var mode: QuoteSheetMode = .options
    @State private var sourceType: SourceTypeQuote = .manual
    
    @State private var quoteText: String = ""
    @State private var pageText: String = ""

    @State private var isSaving: Bool = false

    @State private var validationMessage: String?
    @State private var saveErrorMessage: String?
    @State private var showSaveError: Bool = false
    
    @State private var showOCRFlow = false
    @State private var ocrStep: OCRFlowStep = .camera
    @State private var capturedImage: UIImage?
    
    // MARK: - Datos
    let bookDetail: UserLibraryBook
    let userBookId: UUID

    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(QuoteViewModel.self) private var quoteViewModel

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            if mode == .options {
                quoteMethodSelector
            }

            if mode == .manual {
                quoteComposer
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .alert(
            String(localized: "save_error_title"),
            isPresented: $showSaveError
        ) {
            Button(String(localized: "common_ok"), role: .cancel) { }
        } message: {
            Text(
                saveErrorMessage
                ?? String(localized: "unexpected_error")
            )
        }
        .fullScreenCover(isPresented: $showOCRFlow) {

            switch ocrStep {

            case .camera:

                CameraPickerView(
                    onCapture: { image in
                        capturedImage = image
                        ocrStep = .crop
                    },
                    onCancel: {
                        showOCRFlow = false
                    }
                )
                .ignoresSafeArea()

            case .crop:

                if let capturedImage {

                    CropImageView(
                        image: capturedImage,
                        onCancel: {
                            self.capturedImage = nil
                            ocrStep = .camera
                        },
                        onCrop: { croppedImage in

                            processOCR(from: croppedImage)

                            showOCRFlow = false
                            self.capturedImage = nil
                        }
                    )

                } else {
                    ProgressView()
                }
            }
        }
    }
    

    // MARK: - Selector de método
    private var quoteMethodSelector: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(String(localized: "quote_add_title"))
                .font(.title2)
                .fontWeight(.bold)

            Text(String(localized: "quote_add_method"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Button {
                mode = .manual
                sourceType = .manual
            } label: {
                Label(
                    String(localized: "quote_type_manually"),
                    systemImage: "pencil"
                )
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.glassProminent)
            .tint(.colorPrimary)

            Button {
                capturedImage = nil
                sourceType = .ocr
                showOCRFlow = true
            } label: {
                Label(
                    String(localized: "quote_scan_camera"),
                    systemImage: "camera"
                )
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.glassProminent)
            .tint(.colorPrimaryStrong)
        }
    }

    // MARK: - Compositor de cita manual
    private var quoteComposer: some View {
        QuoteComposerView(
            quoteText: $quoteText,
            pageText: $pageText,
            validationMessage: $validationMessage,
            isSaving: isSaving,
            onSave: {
                Task {
                    do {
                        try await saveQuote()
                    } catch {
                        saveErrorMessage = String(localized: "quote_save_error")
                        showSaveError = true
                        print("ERROR GUARDANDO CITA:", error)
                    }
                }
            },
            onCamera: {
                mode = .ocr
            }
        )
    }

    // MARK: - Guardar cita
    private func saveQuote() async throws {
        guard let input = checkInput() else {
            return
        }

        isSaving = true
        defer { isSaving = false }

        try await quoteViewModel.saveQuote(
            userBookId: userBookId,
            content: input.content,
            pageNumber: input.pageNumber,
            sourceType: sourceType
        )

        dismiss()
    }

    // MARK: - Validar datos
    private func checkInput() -> (content: String, pageNumber: Int?)? {
        validationMessage = nil

        let textoFormateado = quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let paginaTexto = pageText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !textoFormateado.isEmpty else { return nil }

        // La página es opcional
        if paginaTexto.isEmpty {
            return (
                content: textoFormateado,
                pageNumber: nil
            )
        }

        guard let pageNumber = Int(paginaTexto), pageNumber > 0 else {
            validationMessage = String(localized: "quote_invalid_page")
            return nil
        }
        if let totalPages = bookDetail.edition.numberOfPages, pageNumber > totalPages {
            validationMessage = String(format: String(localized: "book_total_pages_message"), totalPages)
            return nil
        }

        return (content: textoFormateado, pageNumber: pageNumber)
    }
    
    private func processOCR(from image: UIImage) {
        do {
            let recognizedText = try ocrService.extraerTexto(
                from: image
            )

            quoteText = recognizedText
            sourceType = .ocr
            mode = .manual

        } catch {
            print("Error realizando OCR: \(error)")
        }
    }
}
