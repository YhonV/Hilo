//
//  ReadingActionSheetView.swift
//  Hilo
//
//  Created by Cactu on 20-09-26.
//

import SwiftUI


struct ReadingActionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LibraryViewModel.self) private var libraryViewModel
    
    @State private var currentPage: Int
    @State private var successFeedback = false
    @State private var errorFeedback = false
    
    let bookDetail: UserLibraryBook
    
    init(bookDetail: UserLibraryBook) {
        self.bookDetail = bookDetail
        _currentPage = State(initialValue: bookDetail.currentPage ?? 0)
    }

    private var totalPages: Int? { bookDetail.edition.numberOfPages }

    private var progress: Double {
        guard let totalPages,
              totalPages > 0 else {
            return 0
        }

        let value = Double(currentPage) / Double(totalPages)
        return min(max(value, 0), 1)
    }

    private var progressPercentage: Int {
        Int(progress * 100)
    }

    private var title: String {
        switch bookDetail.status.name {
        case "reading": return String(localized: "reading_update_progress")
        case "toRead": return String(localized: "reading_start_reading")
        case "read": return String(localized: "reading_reread")
        default: return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // MARK: - Cabecera

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(bookDetail.book.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // MARK: - Contenido

            switch bookDetail.status.name {
            case "reading": readingContent
            case "toRead": startReadingContent
            case "read": rereadContent
            default: EmptyView()
            }
        }
        .padding(20)
        .sensoryFeedback(.success, trigger: successFeedback)
        .sensoryFeedback(.error, trigger: errorFeedback)
    }

    // MARK: - Actualizar progreso y finalizar lectura
    private var readingContent: some View {

        VStack(alignment: .leading, spacing: 20) {

            VStack(alignment: .leading, spacing: 8) {

                Text("reading_current_page")
                    .font(.headline)

                TextField(
                    String(localized: "reading_page_placeholder"),
                    value: $currentPage,
                    format: .number
                )
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

                if let pageError {
                    Label(
                        pageError,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.red)
                }
            }

            if let totalPages, totalPages > 0 {

                VStack(alignment: .leading, spacing: 8) {

                    Text(String(format: String(localized: "reading_progress_percentage"),progressPercentage))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ProgressView(value: progress)
                        .tint(AppColors.accent)

                    Text(String(format: String(localized: "reading_page_of_total"), currentPage, totalPages))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task {
                    do {

                        if hasFinishedReading {
                            try await libraryViewModel.finishReading(
                                userBookId: bookDetail.userBookId
                            )
                        } else {
                            try await libraryViewModel.updateBookProgres(
                                userBookId: bookDetail.userBookId,
                                currentPage: currentPage
                            )
                            successFeedback.toggle()
                            try? await Task.sleep(for: .milliseconds(150))
                        }

                        dismiss()

                    } catch {
                        errorFeedback.toggle()
                        print("Error actualizando lectura: \(error)")
                    }
                }
            } label: {
                Label(
                    hasFinishedReading
                        ? String(localized: "reading_finish_reading")
                        : String(localized: "reading_save_progress"),
                    systemImage: hasFinishedReading
                        ? "checkmark.circle"
                        : "checkmark"
                )
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.glassProminent)
            .tint(AppColors.accent)
            .disabled(!isPageValid)
            .opacity(isPageValid ? 1 : 0.5)

            // Si desconocemos el total de páginas,
            // el usuario debe finalizar manualmente.
            if !hasKnownTotalPages {

                Button {
                    Task {
                        do {
                            try await libraryViewModel.finishReading(userBookId: bookDetail.userBookId)
                            
                            successFeedback.toggle()
                            try? await Task.sleep(for: .milliseconds(150))

                            dismiss()

                        } catch {
                            errorFeedback.toggle()
                            print("Error finalizando lectura: \(error)")
                        }
                    }
                } label: {
                    Label(
                        "reading_finish_reading",
                        systemImage: "checkmark.circle"
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.glass)
                .tint(AppColors.accent)
            }
        }
    }
    
    private var hasKnownTotalPages: Bool {
        guard let totalPages else {
            return false
        }

        return totalPages > 0
    }
    
    private var hasFinishedReading: Bool {
        guard let totalPages, totalPages > 0 else {
            return false
        }

        return currentPage == totalPages
    }
    
    private var pageError: String? {
        if currentPage < 0 { return String(localized: "reading_page_error_negative")}

        if let totalPages, currentPage > totalPages { return String(format: String(localized: "reading_page_error_exceeds_total"),totalPages)}
        return nil
    }

    private var isPageValid: Bool {
        pageError == nil
    }

    // MARK: - Comenzar lectura

    private var startReadingContent: some View {
        VStack(alignment: .leading, spacing: 20) {

            Label(String(localized: "reading_start_description"), systemImage: "book")
                .foregroundStyle(.secondary)

            Button {
                Task {
                    do {
                        try await libraryViewModel.restartReading(userBookId: bookDetail.userBookId)
                        
                        successFeedback.toggle()
                        try? await Task.sleep(for: .milliseconds(150))
                        
                        dismiss()
                    } catch {
                        errorFeedback.toggle()
                        print("Error actualizando progreso: \(error)")
                    }
                }
                
            } label: {
                Label(String(localized: "reading_start_reading"), systemImage: "book")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.glassProminent)
            .tint(AppColors.accent)
        }
    }

    // MARK: - Volver a leer

    private var rereadContent: some View {
        VStack(alignment: .leading, spacing: 20) {

            Label(String(localized: "reading_reread_description"), systemImage: "arrow.counterclockwise")
                .foregroundStyle(.secondary)

            Button {
                Task {
                    do {
                        try await libraryViewModel.restartReading(userBookId: bookDetail.userBookId)
                        dismiss()
                    } catch {
                        print("Error actualizando progreso: \(error)")
                    }
                }
            } label: {
                Label(String(localized: "reading_reread"), systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.glassProminent)
            .tint(AppColors.accent)
        }
    }
}
