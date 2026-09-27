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
            "No se pudo guardar",
            isPresented: $showSaveError
        ) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(
                saveErrorMessage
                ?? "Ocurrió un error inesperado."
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

            Text("Agregar una cita")
                .font(.title2)
                .fontWeight(.bold)

            Text("¿Cómo quieres agregarla?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Button {
                mode = .manual
                sourceType = .manual
            } label: {
                Label(
                    "Escribir manualmente",
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
                    "Escanear con cámara",
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
                        saveErrorMessage = "No se pudo guardar la cita. Inténtalo nuevamente."
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
            validationMessage = "Ingresa un número de página válido."
            return nil
        }
        if let totalPages = bookDetail.edition.numberOfPages, pageNumber > totalPages {
            validationMessage = "Este libro tiene \(totalPages) páginas."
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
