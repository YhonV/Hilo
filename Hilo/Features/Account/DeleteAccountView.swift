import SwiftUI

struct DeleteAccountView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var understandsDeletion = false
    @State private var showsConfirmation = false

    var body: some View {
        Form {
            Section {
                Label("account_delete_heading", systemImage: "person.crop.circle.badge.minus")
                    .font(.headline)
                Text("account_delete_explanation")
                    .foregroundStyle(.secondary)
                if let email = auth.currentUser?.email {
                    Text(email).font(.subheadline.weight(.semibold))
                }
            }
            Section("account_delete_data_title") {
                Label("account_delete_profile_data", systemImage: "person.crop.circle")
                Label("account_delete_reading_data", systemImage: "books.vertical")
                Label("account_delete_quotes_data", systemImage: "quote.opening")
                Label("account_delete_preferences_data", systemImage: "bell.slash")
            }
            Section {
                Toggle("account_delete_acknowledge", isOn: $understandsDeletion)
                    .disabled(auth.isDeletingAccount)
                Button("account_delete_action", role: .destructive) {
                    AppHaptics.warning()
                    showsConfirmation = true
                }
                .disabled(!understandsDeletion || auth.isDeletingAccount)
                if auth.accountDeletionFailed {
                    Text("account_delete_error")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            } footer: {
                Text("account_delete_irreversible")
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .tint(AppColors.accent)
        .navigationTitle("account_delete_title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(auth.isDeletingAccount)
        .interactiveDismissDisabled(auth.isDeletingAccount)
        .alert("account_delete_confirm_title", isPresented: $showsConfirmation) {
            Button("account_delete_cancel", role: .cancel) {}
            Button("account_delete_confirm_action", role: .destructive) {
                Task {
                    await auth.deleteAccount()
                    if auth.accountDeletionFailed { AppHaptics.error() }
                    else if !auth.isAuthenticated { AppHaptics.success() }
                }
            }
        } message: {
            Text("account_delete_confirm_message")
        }
    }
}
