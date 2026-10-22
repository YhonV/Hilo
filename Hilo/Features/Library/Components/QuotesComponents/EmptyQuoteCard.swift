import SwiftUI

struct EmptyQuoteCard: View {

    enum Style {
        case overlay
        case surface
    }

    var style: Style = .overlay

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 28))
                .foregroundStyle(iconColor)

            Text("No hay citas guardadas")
                .font(.headline)
                .foregroundStyle(titleColor)

            Text("Guarda una cita de este libro para verla aquí.")
                .font(.subheadline)
                .foregroundStyle(subtitleColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderColor, lineWidth: 1)
        }
    }

    private var titleColor: Color {
        switch style {
        case .overlay:
            return .white
        case .surface:
            return AppColors.titles
        }
    }

    private var subtitleColor: Color {
        switch style {
        case .overlay:
            return .white.opacity(0.65)
        case .surface:
            return AppColors.secondaryText
        }
    }

    private var iconColor: Color {
        switch style {
        case .overlay:
            return .white.opacity(0.7)
        case .surface:
            return AppColors.accent
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .overlay:
            Rectangle()
                .fill(.ultraThinMaterial)

        case .surface:
            AppColors.surface
        }
    }

    private var borderColor: Color {
        switch style {
        case .overlay:
            return .white.opacity(0.1)
        case .surface:
            return AppColors.border.opacity(0.5)
        }
    }
}
