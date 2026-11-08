//
//  ForgotPasswordView.swift
//  Hilo
//
//  Created by Yhon Vivas on 24-02-26.
//
import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    
    @State private var emailSent = false
    @State private var resendAfter = Date.distantPast
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
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding(.bottom, 5)
                        
                        // ==== FORM PARA RECUPERAR CONTRASEÑA ==== //
                        VStack (spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundColor(AppColors.primary)
                                    .frame(width: 20)
                                
                                TextField("form_email_placeholder", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .textContentType(.emailAddress)
                            }
                            .padding()
                            .background(AppColors.background.opacity(0.65))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 1.2)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                    .background(AppColors.surface)
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
                            .foregroundColor(AppColors.primary)
                        
                        Text(emailSent ? "recovery_email_sent" : "forgot_password_disclaimer")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // BOTÓN FIJO
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Button {
                            Task {
                                do {
                                    try await forgotPassword(email: email)
                                } catch {
                                    errorMessage = String(localized: "auth_recovery_error")
                                    showError = true
                                }
                            }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(emailSent ? "recovery_resend" : "forgot_password_button")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(AppColors.primaryStrong)
                        .padding(.horizontal, 20)
                        .disabled(isLoading || context.date < resendAfter)
                    }
                }
                .padding(.bottom, 40)
            }
            .alert(String(localized: "common_error"), isPresented: $showError) {
                Button(String(localized: "common_ok"), role: .cancel) { }
            } message: {
                Text(LocalizedStringKey(errorMessage ?? "error_unknown"))
            }
        }
    }
    
    
    func forgotPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil else {
            errorMessage = "recovery_invalid_email"
            showError = true
            return
        }
        
        try await AuthService.shared.resetPassword(email: email)
        emailSent = true
        resendAfter = Date().addingTimeInterval(60)
    }

}
