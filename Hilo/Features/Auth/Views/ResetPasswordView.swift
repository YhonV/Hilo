import SwiftUI

struct ResetPasswordView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmationVisible = false
    @State private var isSaving = false
    @State private var didSave = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image("hilo-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    if auth.isOpeningRecoveryLink || auth.isRestoringSession {
                        ProgressView("recovery_opening")
                    } else if didSave {
                        Text("recovery_success")
                        Button("recovery_continue") { auth.finishPasswordRecovery() }
                            .buttonStyle(.borderedProminent)
                    } else if auth.recoveryLinkFailed || auth.session == nil {
                        Text("recovery_invalid_link")
                        cancelButton
                    } else {
                        Text("recovery_new_password").font(.title2.bold())
                        Text("recovery_password_hint")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                        VStack(spacing: 16) {
                            passwordField("form_password_placeholder", text: $password, isVisible: $isPasswordVisible)
                            passwordField("recovery_confirm_password", text: $confirmation, isVisible: $isConfirmationVisible)
                        }
                        if let errorMessage {
                            Text(errorMessage).foregroundStyle(.red)
                        }
                        Button {
                            Task { await save() }
                        } label: {
                            if isSaving { ProgressView() }
                            else { Text("recovery_save") }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving || password.isEmpty || confirmation.isEmpty)
                        cancelButton
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 24))
                .padding(20)
            }
            .background(AppColors.background)
            .tint(AppColors.primaryStrong)
            .navigationTitle("recovery_title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func passwordField(_ placeholder: LocalizedStringKey, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundColor(AppColors.primary)
                .frame(width: 20)

            Group {
                if isVisible.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .textContentType(.newPassword)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye" : "eye.slash")
                    .foregroundStyle(AppColors.secondaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(localized: isVisible.wrappedValue ? "hide_password" : "show_password")
            )
        }
        .padding()
        .background(AppColors.background.opacity(0.65))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 1.2)
        )
        .cornerRadius(12)
    }

    private var cancelButton: some View {
        Button("recovery_back_to_login") {
            Task { await auth.cancelPasswordRecovery() }
        }
        .disabled(isSaving)
    }

    @MainActor
    private func save() async {
        guard password.count >= 8 else {
            errorMessage = String(localized: "recovery_password_hint")
            return
        }
        guard password == confirmation else {
            errorMessage = String(localized: "recovery_password_mismatch")
            return
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await AuthService.shared.updatePassword(password)
            password = ""
            confirmation = ""
            didSave = true
        } catch {
            errorMessage = String(localized: "recovery_save_error")
        }
    }
}
