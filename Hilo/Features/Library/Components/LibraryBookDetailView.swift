//
//  LibraryBookDetailView.swift
//  Hilo
//
//  Created by Cactu on 19-09-26.
//

import SwiftUI

struct LibraryBookDetailView: View {
    let bookDetail: UserLibraryBook
    @State private var coverImage: UIImage?
    @State private var showReadingStatusOptions: Bool = false
    @State private var triggerSensoryFeedback = false
    
    @Environment(LibraryViewModel.self) private var libraryViewModel
    private var currentBook: UserLibraryBook {
        libraryViewModel.userBooks.first {
            $0.userBookId == bookDetail.userBookId
        } ?? bookDetail
    }
    
    private var progress: Double {
        guard let currentPage = currentBook.currentPage,
              let totalPages = currentBook.edition.numberOfPages,
              totalPages > 0 else {
            return 0
        }

        let value = Double(currentPage) / Double(totalPages)

        return min(max(value, 0), 1)
    }

    private var progressPercentage: Int {Int(progress * 100)}
    
    var body: some View {
        ZStack {
            ImageGradient(image: coverImage).ignoresSafeArea()
            ScrollView {
                // MARK: - Portada, titulo, progreso del libro
                coverTitleAndBookProgres
                
                // MARK: - Acciones - Acción principal según estado
                VStack {
                    Button {
                        showReadingStatusOptions = true
                        triggerSensoryFeedback.toggle()
                    } label: {
                        Group {
                                if currentBook.status.name == "read" {
                                    Label("Volver a leer", systemImage: "arrow.counterclockwise")
                                } else if currentBook.status.name == "toRead" {
                                    Label("Comenzar lectura", systemImage: "book")
                                } else {
                                    Label("Actualizar progreso", systemImage: "book.pages")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .buttonStyle(.glassProminent)
                    .tint(AppColors.accent)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 5)
                    .sheet(isPresented: $showReadingStatusOptions) {
                        ReadingActionSheetView(bookDetail: currentBook)
                            .presentationDetents([
                                .height(readingSheetHeight)
                            ])
                            .presentationDragIndicator(.visible)
                    }
                    .sensoryFeedback(.increase,trigger: triggerSensoryFeedback)
                }
                
                VStack {
                    HStack(spacing: 12) {
                        
                        // Cambiar estado
                        Button {

                        } label: {
                            Label("Cambiar estado", systemImage: "arrow.triangle.2.circlepath")
                                .font(.subheadline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.white)
                        .foregroundStyle(.black)
                        .fontWeight(.semibold)
                        
                        // Agregar cita
                        Button {

                        } label: {
                            Label("Agregar cita", systemImage: "quote.bubble")
                                .font(.subheadline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.white)
                        .foregroundStyle(.black)
                        .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                }
                
                
                
                
                // MARK: - Citas asociadas al libro
            }
            .task {
                await getCoverImage()
            }
        }
    }
    
    private func getCoverImage() async {
        guard let url = URL(string: currentBook.edition.coverUrl!) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return }
            coverImage = image
        } catch {
            print("Error descargando portada: \(error)")
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "es_ES")
        outputFormatter.dateFormat = "d MMM yyyy"

        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }

        return outputFormatter.string(from: date)
    }
    
    private var readingSheetHeight: CGFloat {
        switch currentBook.status.name {
        case "reading":
            return 380

        case "toRead", "read":
            return 250

        default:
            return 300
        }
    }
    
    private var coverTitleAndBookProgres: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.bottom, 10)
                } else {
                    ProgressView()
                        .scaledToFit()
                        .frame(width: 120, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.bottom, 10)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                
                let authors = currentBook.book.bookAuthors
                    .map { $0.author.name }
                    .joined(separator: ", ")
                
                Text(currentBook.book.title)
                    .font(.title.bold())
                    .lineLimit(2)
                    .foregroundStyle(.white)
                    .padding(.bottom, 10)
                
                Text(authors)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.bottom, 10)
                
                // LEYENDO
                if currentBook.status.name == "reading" {
                    if let currentPage = currentBook.currentPage,
                       let totalPages = currentBook.edition.numberOfPages,
                       totalPages > 0  {

                        Text("\(progressPercentage)% leído")
                            .font(.subheadline)
                            .foregroundStyle(.white)

                        ProgressView(value: progress)
                            .tint(AppColors.accent)

                        Text(
                            "Página \(currentPage) de \(totalPages)"
                        )
                        .font(.footnote)
                        .foregroundStyle(.white)

                    } else if let currentPage = currentBook.currentPage {
                        Text("Página \(currentPage)")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }
                }
                
                // POR LEER
                if currentBook.status.name == "toRead" {
                    Label (
                        String("Aún no inicias la lectura"),
                        systemImage: "tray"
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
                
                // LEÍDO
                if currentBook.status.name == "read" {
                    if let finishedAt = currentBook.finishedAt {
                        Label(
                            "Finalizado el \(formatDate(finishedAt))",
                            systemImage: "checkmark.circle"
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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
}
