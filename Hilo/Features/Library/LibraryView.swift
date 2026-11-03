import SwiftUI

struct LibraryView: View {

    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(QuoteViewModel.self) private var quoteViewModel
    @Environment(LibraryViewModel.self) private var libraryViewModel
    @State private var showsQuotesGrid = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: - Leyendo, leídos y por leer
                        VStack(spacing: 16) {
                            LibraryBooksSectionView(userLibraryBooks: libraryViewModel.userBooks)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(String(localized: "quotes_yours"))
                                        .font(.headline)

                                    Spacer()

                                    if !quoteViewModel.userQuotes.isEmpty {
                                        Button {
                                            showsQuotesGrid.toggle()
                                        } label: {
                                            Label(
                                                showsQuotesGrid
                                                    ? String(localized: "collection_show_carousel")
                                                    : String(localized: "quotes_show_grid"),
                                                systemImage: showsQuotesGrid
                                                    ? "rectangle.portrait.on.rectangle.portrait"
                                                    : "square.grid.2x2"
                                            )
                                            .labelStyle(.iconOnly)
                                            .font(.body.weight(.medium))
                                            .frame(width: 28, height: 28)
                                        }
                                        .buttonStyle(.glass)
                                        .buttonBorderShape(.circle)
                                        .controlSize(.regular)
                                        .tint(AppColors.accent)
                                    }
                                }

                                if quoteViewModel.userQuotes.isEmpty {
                                    EmptyQuoteCard(style: .surface)
                                } else if showsQuotesGrid {
                                    LazyVGrid(
                                        columns: [GridItem(.adaptive(minimum: 280), spacing: 14, alignment: .top)],
                                        alignment: .leading,
                                        spacing: 14
                                    ) {
                                        ForEach(quoteViewModel.userQuotes, id: \.id) { quote in
                                            LibraryQuoteHighlightCard(quote: quote)
                                        }
                                    }
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(alignment: .top, spacing: 14) {
                                            ForEach(quoteViewModel.userQuotes, id: \.id) { quote in
                                                LibraryQuoteHighlightCard(quote: quote)
                                                    .containerRelativeFrame(.horizontal) { width, _ in
                                                        max(0, width - 28)
                                                    }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            CalendarView()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }
            }
            .task {
                guard let userId = authViewModel.currentUser?.id else {
                    return
                }
                
                do {
                    async let booksTask = libraryViewModel.getUserBooks(userId: userId)
                    async let quotesTask = quoteViewModel.getAllQuotes(userId: userId)
                    _ = try await (booksTask, quotesTask)
                } catch {
                    print("Error obteniendo biblioteca y citas: \(error)")
                }
            }
        }
        .environment(libraryViewModel)
    }
}
