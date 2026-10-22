//
//  BookDetailView.swift
//  Hilo
//
//  Created by Cactu on 09-08-26.
//
import SwiftUI
import Nuke

struct BookDetailView: View {
    let book: Book
    @State private var isLoading: Bool = false
    @State private var showReadingStatusOptions: Bool = false
    @State private var isDescriptionExpanded = false
    @State private var statusFeedbackTrigger = 0
    @State private var bookDetailViewModel: BookDetailViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var isCheckingBookStatus = true
    @State private var coverImage: UIImage?
    @State private var isLoadingCover = false
    @State private var coverRequestID = UUID()
    
    private var buttonTitle: String {
        switch bookDetailViewModel.bookStatus {
        case .reading: return String(localized: "continue_reading")
        case .read: return String(localized: "read")
        case .toRead: return String(localized: "to_read")
        case nil: return String(localized: "add_to_my_list")
        }
    }
    
    private var buttonIcon: String {
        switch bookDetailViewModel.bookStatus {
        case .reading: return "book.fill"
        case .toRead: return "bookmark.fill"
        case .read: return "checkmark.circle.fill"
        case nil: return "plus"
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch bookDetailViewModel.bookStatus {
        case .reading: return AppColors.accent
        case .toRead: return AppColors.surface
        case .read: return AppColors.primary
        case nil: return AppColors.primaryStrong
        }
    }
    
    private var buttonForegroundColor: Color {
        switch bookDetailViewModel.bookStatus {
        case .toRead: return AppColors.primaryStrong
        default: return .white
        }
    }
    
    private var buttonBorderColor: Color {
        switch bookDetailViewModel.bookStatus {
        case .toRead: return AppColors.primary.opacity(0.25)
        default: return .clear
        }
    }
    
    init(book: Book) {
            self.book = book
            _bookDetailViewModel = State(
                initialValue: BookDetailViewModel(book: book)
            )
        }
    
    var body: some View {
        ZStack {
            if bookDetailViewModel.isInitialLoading {
                BookDetailLoadingView()
            } else {
                ImageGradient(image: coverImage).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        Group {
                            if let coverImage {
                                Image(uiImage: coverImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 260)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                    .padding(.bottom, 10)
                            } else if isLoadingCover {
                                ProgressView()
                                    .frame(width: 180, height: 260)
                            } else {
                                Image("no-cover")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 260)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            
                            Text(bookDetailViewModel.book.title)
                                .font(.title.bold())
                                .lineLimit(3)
                                .foregroundStyle(.white)
                            
                            Text(bookDetailViewModel.book.authors.first ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            
                            // Métricas
                            HStack(spacing: 8) {
                                
                                if let rating = bookDetailViewModel.book.averageRating {
                                    Label(
                                        String(format: "%.1f", rating),
                                        systemImage: "star.fill"
                                    )
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        .white.opacity(0.12),
                                        in: Capsule()
                                    )
                                    .overlay {
                                        Capsule()
                                            .stroke(
                                                .white.opacity(0.20),
                                                lineWidth: 1
                                            )
                                    }
                                    .foregroundStyle(.white)
                                    .fontWeight(.semibold)
                                    .fixedSize()
                                }
                                
                                if let numberOfPages = bookDetailViewModel.book.numberOfPages, numberOfPages > 0 {
                                    Label(
                                        String(
                                            format: String(localized: "book_pages_count"),
                                            numberOfPages
                                        ),
                                        systemImage: "book.pages"
                                    )
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        .white.opacity(0.12),
                                        in: Capsule()
                                    )
                                    .overlay {
                                        Capsule()
                                            .stroke(
                                                .white.opacity(0.20),
                                                lineWidth: 1
                                            )
                                    }
                                    .foregroundStyle(.white)
                                    .fontWeight(.semibold)
                                    .fixedSize()
                                }
                                
                                if let publishedDate = bookDetailViewModel.book.publishedDate {
                                    Label(
                                        publishedDate,
                                        systemImage: "calendar"
                                    )
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        .white.opacity(0.12),
                                        in: Capsule()
                                    )
                                    .overlay {
                                        Capsule()
                                            .stroke(
                                                .white.opacity(0.20),
                                                lineWidth: 1
                                            )
                                    }
                                    .foregroundStyle(.white)
                                    .fontWeight(.semibold)
                                    .fixedSize()
                                }
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            
                            // Géneros
                            if !bookDetailViewModel.book.genre.isEmpty {
                                HStack(spacing: 8) {
                                    ForEach(bookDetailViewModel.book.genre, id: \.self) { genre in
                                        Text(genre.localizedName)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(
                                                .white.opacity(0.12),
                                                in: Capsule()
                                            )
                                            .overlay {
                                                Capsule()
                                                    .stroke(
                                                        .white.opacity(0.20),
                                                        lineWidth: 1
                                                    )
                                            }
                                            .foregroundStyle(.white)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        
                        // MARK: - Ediciones disponibles

                        if bookDetailViewModel.isLoadingEditions {

                            ProgressView()
                                .tint(.white)
                                .padding()

                        } else if !bookDetailViewModel.displayEditions.isEmpty {

                            VStack(alignment: .leading, spacing: 12) {

                                HStack {
                                    Text(String(localized: "editions_title"))
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if bookDetailViewModel.displayEditions.count > 10 {
                                        Button(bookDetailViewModel.showsAllEditions ? String(localized: "show_less") : String(localized: "editions_show_all")) {
                                            bookDetailViewModel.showsAllEditions.toggle()
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    }
                                }
                                .padding(.horizontal, 20)

                                ScrollView(.horizontal, showsIndicators: false) {

                                    LazyHStack(alignment: .top, spacing: 12) {

                                        ForEach(
                                            bookDetailViewModel.visibleEditions,
                                            id: \.key
                                        ) { edition in

                                            BookEditionCard(
                                                edition: edition,
                                                isSelected:
                                                    bookDetailViewModel.selectedEdition?.key
                                                    == edition.key,
                                                isSaved: bookDetailViewModel.savedEdition?.key == edition.key
                                            ) {
                                                bookDetailViewModel.selectEdition(edition)
                                                statusFeedbackTrigger += 1
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .sensoryFeedback(
                                .selection,
                                trigger: statusFeedbackTrigger
                            )
                        }
                        
                        if let message = bookDetailViewModel.librarySelectionError ?? bookDetailViewModel.editionsError {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                        }

                        Button {
                            showReadingStatusOptions = true
                        } label: {
                            Group {
                                if isCheckingBookStatus {
                                    ProgressView()
                                        .tint(.white)
                                } else if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Label(
                                        buttonTitle,
                                        systemImage: buttonIcon
                                    )
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        }
                        .buttonStyle(.glassProminent)
                        .foregroundStyle(buttonForegroundColor)
                        .tint(buttonBackgroundColor)
                        .padding(.horizontal, 20)
                        .disabled(
                            isLoading ||
                            isCheckingBookStatus ||
                            bookDetailViewModel.isLoadingEditions ||
                            !bookDetailViewModel.canSaveEdition
                        )
                        .sheet(isPresented: $showReadingStatusOptions) {
                            ReadingStatusSheet(
                                currentStatus: bookDetailViewModel.bookStatus
                            ) { status in
                                
                                statusFeedbackTrigger += 1
                                
                                Task {
                                    await saveBookToList(status: status)
                                }
                            }
                            .presentationDetents([.height(300)])
                            .presentationDragIndicator(.visible)
                            .presentationCornerRadius(28)
                            .presentationBackground(.ultraThinMaterial)
                        }
                        .sensoryFeedback(.selection, trigger: statusFeedbackTrigger)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            
                            Text("synopsis")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            
                            Text(bookDetailViewModel.book.description ?? String(localized: "no_description"))
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.80))
                                .lineSpacing(2)
                                .lineLimit(isDescriptionExpanded ? nil : 5)
                                .animation(.easeInOut(duration: 0.2), value: isDescriptionExpanded)
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isDescriptionExpanded.toggle()
                                }
                            } label: {
                                Text(isDescriptionExpanded ? String(localized: "show_less") : String(localized: "show_more"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                            .padding(.horizontal, 20)
                        }
                        
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        
        .task {
            do {
                try await bookDetailViewModel.loadBookDetails()
            } catch {
                print("Error cargando detalles:", error)
            }
            bookDetailViewModel.isInitialLoading = false
        }
        .task {
            await bookDetailViewModel.loadEditions()
        }
        .task {
            do {
                try await getUserBook()
            } catch {
                print("Error consultando biblioteca:", error)
            }
        }
        .task(id: bookDetailViewModel.book.cover) {
            await getCoverImage()
        }

    }
        
    
    func saveBookToList(status: BookStatus) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await bookDetailViewModel.saveBook(status: status)
        } catch {
            print("Error guardando libro: \(error)")
        }
    }
    
    func getUserBook() async throws {

        isCheckingBookStatus = true
        defer { isCheckingBookStatus = false }
        guard let userId = authViewModel.currentUser?.id else {
            return
        }
        
        try await bookDetailViewModel.getBooksFromUserLibrary(
            userId: userId
        )
    }
    
    
    @MainActor
    private func getCoverImage() async {
        let requestID = UUID()
        coverRequestID = requestID
        let coverURL = bookDetailViewModel.book.cover
        coverImage = nil
        isLoadingCover = false
        guard !coverURL.isEmpty, let url = URL(string: coverURL) else { return }

        isLoadingCover = true
        defer {
            if coverRequestID == requestID { isLoadingCover = false }
        }
        do {
            let image = try await ImagePipeline.shared.image(for: url)
            guard !Task.isCancelled,
                  coverRequestID == requestID,
                  bookDetailViewModel.book.cover == coverURL else { return }
            coverImage = image
        } catch {
            // Keep the placeholder; an old request must never restore an old cover.
        }
    }
}
