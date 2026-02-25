//
//  ForgotPasswordView.swift
//  Hilo
//
//  Created by Yhon Vivas on 24-02-26.
//
import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage : String?
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView{
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            Image("hilo-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                            
                            Text("forgot_password_subtitle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 5)
                        
                        // ==== FORM PARA RECUPERAR CONTRASEÑA ==== //
                        VStack (spacing: 12) {
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
                        }
                        
                        
                        // LINK A LOGIN
                        HStack(spacing: 4) {
                            NavigationLink (destination: LoginView()){
                                Text("wanna_go_back_to_login")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.primary)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.top, 20)
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
                .scrollIndicators(.hidden)
                
                /// DISCLAIMER + BOTÓN
                VStack(spacing: 12) {
                    // DISCLAIMER
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        
                        Text("Check your spam folder if you don't see the email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // BOTÓN FIJO
                    Button {
                        Task {
                            do {
                                try await forgotPassword(email: email)
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
                            Text("forgot_password_button")
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
                    .disabled(isLoading)
                }
                .padding(.bottom, 40)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(LocalizedStringKey(errorMessage ?? "error_unknown"))
            }
        }
    }
    
    
    func forgotPassword(email: String) async throws {
        isLoading = true
        
        guard !email.isEmpty else {
            errorMessage = "all_fields_required"
            showError = true
            isLoading = false
            return
        }
        
        try await FirestoreService.shared.resetPassword(email: email)
        isLoading = false
        clearFields()
    }
    
    func clearFields() {
        email = ""
    }
}
