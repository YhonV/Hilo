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
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack() {
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
                                .foregroundColor(AppColors.secondaryText)
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
                                        .foregroundColor(AppColors.primary)
                                        .frame(width: 20)
                                    
                                    TextField("form_email_placeholder", text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .focused($isFocused)
                                }
                                .padding()
                                .background(AppColors.background.opacity(0.65))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.border, lineWidth: 1.2)
                                )
                                .cornerRadius(12)
                                
                                // PASSWORD
                                HStack(spacing: 12) {
                                    Image(systemName: "lock")
                                        .foregroundColor(AppColors.primary)
                                        .frame(width: 20)
                                    
                                    SecureField("form_password_placeholder", text: $password)
                                        .focused($isFocused)
                                }
                                .padding()
                                .background(AppColors.background.opacity(0.65))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.border, lineWidth: 1.2)
                                )
                                .cornerRadius(12)
                            }
                            
                            // FORGOT PASSWORD
                            HStack {
                                NavigationLink(destination: ForgotPasswordView()) {
                                    Text("forgot_password_text")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.primary)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                            .padding(.top, 4)
                            
                            // REGISTER
                            HStack {
                                Text("not_registered_yet")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.secondaryText)
                                    .fontWeight(.semibold)
                                
                                NavigationLink(destination: RegisterView()) {
                                    Text("sign_up")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.primary)
                                        .fontWeight(.bold)
                                }
                                Spacer()
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                            
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
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("log_in")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                            }
                            .buttonStyle(.glassProminent)
                            .tint(AppColors.primaryStrong)
                            .padding(.horizontal, 20)
                            .disabled(isLoading)
                            
                            VStack(spacing: 6) {
                                Text("other_ways_to_sign_in")
                                    .font(.footnote)
                                    .foregroundStyle(AppColors.secondaryText)

                                HStack(spacing: 28) {
                                    Button {
                                        print("Google")
                                    } label: {
                                        Image("google-logo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 36, height: 36) // logo
                                            .offset(y: 2)
                                            .frame(width: 52, height: 52) // area tactil boton
                                    }

                                    Button {
                                        print("Apple")
                                    } label: {
                                        Image(systemName: "apple.logo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 42, height: 42)
                                            .frame(width: 52, height: 52)
                                            .foregroundStyle(AppColors.titles)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 28)
                        .background(AppColors.surface)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
                .onTapGesture {
                    isFocused = false
                }
//                .scrollDismissesKeyboard(.immediately)
                .scrollIndicators(.hidden)
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
