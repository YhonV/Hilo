import SwiftUI

struct QuoteComposerView: View {
    @Binding var quoteText: String
    @Binding var pageText: String
    @Binding var validationMessage: String?

    let isSaving: Bool
    let onSave: () -> Void
    let onCamera: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            TextField(
                "Escribe tu cita...",
                text: $quoteText,
                axis: .vertical
            )
            .lineLimit(1...5)
            .textInputAutocapitalization(.sentences)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer(minLength: 12)

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 14) {

                // MARK: - Cámara
                Button {
                    onCamera()
                } label: {
                    Image(systemName: "camera")
                        .foregroundStyle(AppColors.accent)
                        .font(.system(size: 19))
                }
                .frame(width: 36, height: 36)

                // MARK: - Página
                HStack(spacing: 6) {
                    Image(systemName: "book.pages")
                        .font(.caption)

                    TextField(
                        "Página",
                        text: $pageText
                    )
                    .keyboardType(.numberPad)
                    .frame(width: 70)
                    .onChange(of: pageText) {
                        validationMessage = nil
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    AppColors.surface.opacity(0.35),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            AppColors.border.opacity(0.5),
                            lineWidth: 1
                        )
                }

                Spacer()

                // MARK: - Guardar
                Button {
                    onSave()
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(width: 34, height: 34)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 34, height: 34)
                    }
                }
                .buttonStyle(.glassProminent)
                .tint(AppColors.accent)
                .disabled(
                    quoteText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                    || isSaving
                )
            }
            .padding(.horizontal, 16)
        }
        .background(
            .clear,
            in: RoundedRectangle(cornerRadius: 15)
        )
    }
}
