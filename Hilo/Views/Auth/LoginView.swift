//
//  LoginView.swift
//  Hilo
//
//  Created by Yhon Vivas on 08-02-26.
//
import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var isLoading = false
    @State private var errorMessage : String?
    @State private var showError = false
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // CONTENIDO
                VStack(spacing: 0) {
                    // HEADER
                    VStack(alignment: .leading, spacing: 8) {
                        Text("hilo")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(AppColors.primary)

                        Text("login_subtitle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)

                    // FORM
                    VStack(alignment: .leading, spacing: 4) {
                        Text("type_your_credentials")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.titles)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)

                                TextField("form_email_placeholder", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            Divider()
                                .padding(.leading, 48)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)

                                SecureField("password_placeholder", text: $password)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }

                    // FORGOT PASSWORD
                    HStack {
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("forgot_password_text")
                                .font(.subheadline)
                                .foregroundColor(AppColors.primary)
                                .fontWeight(.medium)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    Spacer()

                    // REGISTER
                    NavigationLink(destination: RegisterView()) {
                        Text("register_your_account")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                            .fontWeight(.medium)
                    }
                    .padding(.bottom, 110)
                }
                .background(AppColors.background)

                // BOTÓN FIJO
                Button {
                    Task {
                        do {
                            try await signIn(email: email, password: password)
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("log_in")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.primary)
                .cornerRadius(12)
                .shadow(color: AppColors.primary.opacity(0.3), radius: 10, y: 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .disabled(isLoading)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(LocalizedStringKey(errorMessage ?? "error_unknown"))
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
            }
        }
    }
    
    func signIn(email: String, password: String) async throws{
        isLoading = true
        defer { isLoading = false }
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "all_fields_required"
            showError = true
            isLoading = false
            return
        }
        try await AuthService.shared.signIn(email: email, password: password)
        navigateToHome = true
        clearFields()
    }
    
    func clearFields() {
        email = ""
        password = ""
    }
}

#Preview {
    LoginView()
}
