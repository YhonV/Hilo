//
//  EditProfileView.swift
//  Hilo
//
//  Created by Cactu on 15-08-26.
//
import PhotosUI
import SwiftUI
import Helpers

struct EditProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    private let userService = UserService()
    private let storageService = StorageService()
    
    @State private var displayName: String = ""
    @State private var username: String = ""
    
    @State private var isLoading = false
    @State private var errorMessage : String?
    @State private var showError = false
    @FocusState private var isFocused: Bool
    @State private var isEditing = false
    @State private var saveSucceeded = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var avatarURL: URL?
    @State private var isAvatarLoading = false
    @State private var avatarSaveSucceeded = false
    @State private var hasPendingAvatarChange = false
    
    var body: some View {
        NavigationStack {
            ZStack() {
                // FONDO
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // LOGO + HEADER
                        VStack(spacing: 10) {

                            ZStack {
                                if let selectedImage {

                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()

                                } else if let avatarURL {

                                    AsyncImage(url: avatarURL) { phase in
                                        switch phase {

                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()

                                        case .failure:
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .foregroundStyle(AppColors.secondaryText)

                                        case .empty:
                                            ProgressView()

                                        @unknown default:
                                            EmptyView()
                                        }
                                    }

                                } else {

                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .foregroundStyle(AppColors.secondaryText)
                                }
                            }
                            .frame(width: 115, height: 115)
                            .clipShape(.circle)

                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images
                            ) {
                                Label("Cambiar foto", systemImage: "photo")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundStyle(
                                        isEditing
                                            ? AppColors.primary
                                            : AppColors.secondaryText
                                    )
                                    .padding(.bottom, 10)
                            }
                            .buttonStyle(.plain)
                            .disabled(!isEditing || isLoading)
                        }
                        .onChange(of: selectedPhoto, loadImage)
                        
                        // TARJETA CON FORM
                        VStack(spacing: 12) {
                            // SECCIÓN: DATOS PERSONALES
                            VStack(alignment: .leading, spacing: 16) {
                                // NOMBRE
                                HStack(spacing: 12) {
                                    Image(systemName: "person")
                                        .foregroundColor(AppColors.primary)
                                        .frame(width: 20)
                                    
                                    TextField("form_name_placeholder", text: $displayName)
                                        .autocorrectionDisabled()
                                        .focused($isFocused)
                                        .disabled(!isEditing)
                                        .foregroundStyle(
                                            !isEditing ? AppColors.titles : AppColors.secondaryText
                                        )
                                }
                                .padding()
                                .background(
                                    !isEditing
                                        ? AppColors.background.opacity(0.65)
                                        : AppColors.surface.opacity(0.45)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.border, lineWidth: 1.2)
                                )
                                .cornerRadius(12)
                                
                                // USERNAME
                                HStack(spacing: 12) {
                                    Image(systemName: "at")
                                        .foregroundColor(AppColors.primary)
                                        .frame(width: 20)
                                    
                                    TextField("form_username_placeholder", text: $username)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($isFocused)
                                        .disabled(!isEditing)
                                        .foregroundStyle(
                                            !isEditing ? AppColors.titles : AppColors.secondaryText
                                        )
                                }
                                .padding()
                                .background(
                                    !isEditing
                                        ? AppColors.background.opacity(0.65)
                                        : AppColors.surface.opacity(0.45)
                                )
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
                }
                .scrollIndicators(.hidden)
                .onTapGesture {
                    isFocused = false
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(LocalizedStringKey(errorMessage ?? "error_unknown"))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {

                    if isLoading {

                        ProgressView()

                    } else if saveSucceeded {

                        Image(systemName: "checkmark")
                            .foregroundStyle(AppColors.primaryStrong)
                            .transition(.scale.combined(with: .opacity))

                    } else if isEditing {

                        Button {
                            Task {
                                do {
                                    try await saveProfileChanges()

                                } catch let error as PostgrestError {

                                    if error.code == "23505" {
                                        errorMessage = "username_already_exists"
                                    } else {
                                        errorMessage = "error_updating_profile"
                                    }

                                    showError = true

                                } catch {
                                    errorMessage = "error_unknown"
                                    showError = true
                                }
                            }
                        } label: {
                            Text("Guardar")
                        }
                        .buttonStyle(.glassProminent)
                        .tint(AppColors.primaryStrong)

                    } else {

                        Button("Editar") {
                            isEditing = true
                        }
                    }
                }
            }
            .sensoryFeedback(trigger: saveSucceeded) {
                saveSucceeded ? .success : nil
            }
            .sensoryFeedback(trigger: avatarSaveSucceeded) {
                avatarSaveSucceeded ? .success : nil
            }
            .task(id: authViewModel.currentUser?.id) {
                guard let user = authViewModel.currentUser else { return }
                displayName = user.displayName
                username = user.username
                loadAvatar()
            }
        }
    }
    
    func saveProfileChanges() async throws {

        guard
            let userId = authViewModel.currentUser?.id,
            !username.isEmpty,
            !displayName.isEmpty
        else {
            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        // Foto
        if hasPendingAvatarChange {
            try await updateAvatar()
        }

        // Datos básicos
        let finalUsername = username.hasPrefix("@")
            ? username
            : "@" + username

        authViewModel.currentUser =
            try await userService.updateUserBasicInformation(
                uid: userId,
                username: finalUsername,
                displayName: displayName
            )

        hasPendingAvatarChange = false
        selectedPhoto = nil
        isEditing = false
        isFocused = false

        withAnimation(.snappy) {
            saveSucceeded = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.5))

            withAnimation(.snappy) {
                saveSucceeded = false
            }
        }
    }
    
    func clearFields() {
        displayName = ""
        username = ""
    }
    
    func resizeImage(_ image: UIImage, maxSize: CGSize) -> UIImage {

        let widthRatio = maxSize.width / image.size.width
        let heightRatio = maxSize.height / image.size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(
            width: image.size.width * ratio,
            height: image.size.height * ratio
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func loadImage() {

        Task {
            do {
                guard let imageData = try await selectedPhoto?
                    .loadTransferable(type: Data.self)
                else {
                    return
                }

                guard let inputImage = UIImage(data: imageData) else {
                    return
                }

                selectedImage = resizeImage(
                    inputImage,
                    maxSize: CGSize(width: 512, height: 512)
                )

                hasPendingAvatarChange = true

            } catch {
                errorMessage = "error_loading_profile_picture"
                showError = true
            }
        }
    }
    
    func updateAvatar() async throws {

        guard let userId = authViewModel.currentUser?.id else {
            return
        }

        guard let selectedImage else {
            return
        }

        guard let imageData = selectedImage.jpegData(
            compressionQuality: 0.8
        ) else {
            return
        }

        _ = try await storageService.uploadAvatar(
            userId: userId,
            imageData: imageData
        )
    }
    
    func loadAvatar() {
        guard let userId = authViewModel.currentUser?.id else {
            return
        }

        do {
            avatarURL = try storageService.getAvatarURL(userId: userId)
        } catch {
            print("Error obteniendo avatar:", error)
        }
    }
}

#Preview {
    EditProfileView()
}
