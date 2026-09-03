//
//  BookDetailView.swift
//  Hilo
//
//  Created by Cactu on 09-08-26.
//
import SwiftUI

enum BookStatus: String, Codable {
    case reading
    case read
    case toRead
}

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
    
    private var buttonTitle: String {
        switch bookDetailViewModel.bookStatus {
        case .reading:
            return String(localized: "continue_reading")
        case .read:
            return String(localized: "read")
        case .toRead:
            return String(localized: "to_read")
        case nil:
            return String(localized: "add_to_my_list")
        }
    }
    
    private var buttonIcon: String {
        switch bookDetailViewModel.bookStatus {
        case .reading:
            return "book.fill"

        case .toRead:
            return "bookmark.fill"

        case .read:
            return "checkmark.circle.fill"

        case nil:
            return "plus"
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch bookDetailViewModel.bookStatus {
        case .reading:
            return AppColors.accent

        case .toRead:
            return AppColors.surface

        case .read:
            return AppColors.primary

        case nil:
            return AppColors.primaryStrong
        }
    }
    
    private var buttonForegroundColor: Color {
        switch bookDetailViewModel.bookStatus {
        case .toRead:
            return AppColors.primaryStrong

        default:
            return .white
        }
    }
    
    private var buttonBorderColor: Color {
        switch bookDetailViewModel.bookStatus {
        case .toRead:
            return AppColors.primary.opacity(0.25)

        default:
            return .clear
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
                        } else {
                            ProgressView()
                                .frame(width: 180, height: 260)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 6) {

                        Text(book.title)
                            .font(.title.bold())
                            .lineLimit(3)
                            .foregroundStyle(.white)

                        Text(book.authors.first ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {

                        // Métricas
                        HStack(spacing: 8) {

                            if let rating = book.averageRating {
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

                            if let numberOfPages = book.numberOfPages, numberOfPages > 0 {
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

                            if let publishedDate = book.publishedDate {
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
                        if !book.genre.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(book.genre, id: \.self) { genre in
                                    Text(genre)
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
                    .disabled(isLoading)
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

                        Text(book.description ?? "no_description")
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
                            Text(isDescriptionExpanded ? "show_less" : "show_more")
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
            .toolbar(.hidden, for: .tabBar)
            .task {
                do {
                    await getCoverImage()
                    try await getUserBook()
                } catch {
                    print("Error al obtener el libro: \(error)")
                }
            }
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

        guard let userId = authViewModel.currentUser?.id else {
            return
        }
        isCheckingBookStatus = true
        defer { isCheckingBookStatus = false }
        
        try await bookDetailViewModel.getBooksFromUserLibrary(
            userId: userId
        )
    }
    
    private func getCoverImage() async {
        guard let url = URL(string: book.cover) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return }
            coverImage = image
        } catch {
            print("Error descargando portada: \(error)")
        }
        
    }
}
