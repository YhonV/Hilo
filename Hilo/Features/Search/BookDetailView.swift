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

struct ReadingStatusSheet: View {

    let currentStatus: BookStatus?
    let onSelect: (BookStatus) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        VStack(alignment: .leading, spacing: 20) {

            VStack(alignment: .leading, spacing: 4) {
                Text("Estado de lectura")
                    .font(.title2.bold())

                Text("Selecciona dónde quieres guardar este libro.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {

                statusButton(
                    title: "Leyendo",
                    subtitle: "Lo estoy leyendo actualmente",
                    icon: "book.fill",
                    status: .reading,
                    color: AppColors.accent
                )

                statusButton(
                    title: "Por leer",
                    subtitle: "Quiero leerlo más adelante",
                    icon: "bookmark.fill",
                    status: .toRead,
                    color: AppColors.secondaryText
                )

                statusButton(
                    title: "Leído",
                    subtitle: "Ya terminé este libro",
                    icon: "checkmark.circle.fill",
                    status: .read,
                    color: AppColors.primary
                )
            }
        }
        .padding(20)
        .background(AppColors.background)
    }

    private func statusButton(
        title: String,
        subtitle: String,
        icon: String,
        status: BookStatus,
        color: Color
    ) -> some View {

        Button {
            onSelect(status)
            dismiss()
        } label: {

            HStack(spacing: 14) {

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if currentStatus == status {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(color)
                }
            }
            .padding(14)
            .background(
                color.opacity(currentStatus == status ? 0.12 : 0.06),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        color.opacity(currentStatus == status ? 0.30 : 0.10),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColors.titles)
    }
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
            return "Continuar leyendo"
        case .read:
            return "Leído"
        case .toRead:
            return "Por leer"
        case nil:
            return "Agregar a mi lista"
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
                    
                    
//                    Image(uiImage: coverImage) { phase in
//                        switch phase {
//                        case .success(let image):
//                            image
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 180, height: 260)
//                                .clipShape(RoundedRectangle(cornerRadius: 20))
//                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
//                                .padding(.bottom, 10)
//                        case .failure:
//                            Image(systemName: "photo")
//                                .resizable()
//                                .scaledToFit()
//                                .foregroundStyle(.secondary)
//                                .padding(30)
//                                .frame(width: 180, height: 260)
//                        case .empty:
//                            ProgressView()
//                                .frame(width: 180, height: 260)
//                        @unknown default:
//                            EmptyView()
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
                    
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

                            if book.numberOfPages > 0 {
                                Label(
                                    "\(book.numberOfPages) páginas",
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
                        .presentationDetents([.height(330)])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(28)
                    }
                    .sensoryFeedback(.selection, trigger: statusFeedbackTrigger)
                    
                    VStack(alignment: .leading, spacing: 10) {

                        Text("Sinopsis")
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text(book.description ?? "no-description")
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
                            Text(isDescriptionExpanded ? "Ver menos" : "Ver más")
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
