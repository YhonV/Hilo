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
                // FONDO
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // LOGO + HEADER
                        VStack(spacing: 16) {
                            Image("hilo-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                            
                            Text("login_subtitle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                        
                        // TARJETA CON FORM
                        VStack(spacing: 20) {
                            // TÍTULO DEL FORM
                            Text("type_your_credentials")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.titles)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                            
                            // CAMPOS
                            VStack(spacing: 16) {
                                // EMAIL
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)

                                    TextField("form_email_placeholder", text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                }
                                .padding()
                                .background(AppColors.background)
                                .cornerRadius(12)
                                
                                // PASSWORD
                                HStack(spacing: 12) {
                                    Image(systemName: "lock")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)

                                    SecureField("password_placeholder", text: $password)
                                }
                                .padding()
                                .background(AppColors.background)
                                .cornerRadius(12)
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
                            .padding(.top, 4)
                            
                            // REGISTER
                            HStack {
                                Text("not_registered_yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                                
                                NavigationLink(destination: RegisterView()) {
                                    Text("sign_up")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.primary)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 28)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
                .scrollIndicators(.hidden)

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
                .frame(height: 56)
                .background(AppColors.primary)
                .cornerRadius(16)
                .shadow(color: AppColors.primary.opacity(0.3), radius: 12, y: 6)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
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
            .navigationBarHidden(true)
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
