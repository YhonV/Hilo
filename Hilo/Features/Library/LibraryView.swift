import SwiftUI

struct LibraryView: View {

    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(QuoteViewModel.self) private var quoteViewModel
    @Environment(LibraryViewModel.self) private var libraryViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: - Leyendo, leídos y por leer
                        VStack(spacing: 5) {
                            Text("Tu biblioteca")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 12)
                                         
                            LibraryBooksSectionView(userLibraryBooks: libraryViewModel.userBooks)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .task {
                guard let userId = authViewModel.currentUser?.id else {
                    return
                }
                
                do {
                    try await libraryViewModel.getUserBooks(userId: userId)
                } catch {
                    print("Error obteniendo biblioteca: \(error)")
                }
            }
        }
        .environment(libraryViewModel)
    }
}
