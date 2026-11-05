import SwiftUI

struct QuoteShareCardView: View {
    let quoteText: String
    let sourceTitle: String
    let formattedDate: String
    let pageText: String?
    let coverImage: UIImage?
    let templateImage: UIImage?
    let template: ShareTemplateDefinition
    let palette: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            Text(String(localized: "quote_opening_mark"))
                .font(.system(size: 96, weight: .bold, design: .serif))
                .foregroundStyle(template.foregroundColor.opacity(0.9))
                .frame(height: 66, alignment: .topLeading)

            Text(quoteText)
                .font(.system(size: quoteFontSize, weight: .medium, design: .serif))
                .foregroundStyle(template.foregroundColor)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 20)

            HStack(spacing: 20) {
                if let coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 86, height: 122)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(0.18))
                        .frame(width: 86, height: 122)
                        .overlay(Image(systemName: "book.closed").font(.title2))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(sourceTitle)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)
                    if let pageText {
                        Text(pageText)
                            .font(.subheadline)
                    }
                    Text(formattedDate)
                        .font(.subheadline)
                }
                .foregroundStyle(template.foregroundColor.opacity(0.86))
            }

            HStack(spacing: 12) {
                Spacer()

                Image("hilo-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(String(localized: "quote_watermark_name"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            .foregroundStyle(watermarkForeground)
        }
        .padding(64)
        .frame(width: 900)
        .frame(minHeight: 1100, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 52, style: .continuous))
    }

    @ViewBuilder
    private var background: some View {
        switch template.kind {
        case "cover_dynamic":
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0),
                    SIMD2(0, 0.5), SIMD2(0.5, 0.5), SIMD2(1, 0.5),
                    SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1)
                ],
                colors: meshColors
            )
            .overlay(Color.black.opacity(0.2))
        case "image":
            if let templateImage {
                Image(uiImage: templateImage)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(template.config.overlayOpacity ?? 0.2))
            } else {
                LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        default:
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var meshColors: [Color] {
        let colors = palette.count >= 3 ? palette : CoverPalette.fallback
        return [colors[0], colors[0], colors[1], colors[0], colors[1], colors[2], colors[1], colors[2], colors[2]]
    }

    private var gradientColors: [Color] {
        template.colors.isEmpty ? [AppColors.surface, AppColors.border] : template.colors
    }

    private var quoteFontSize: CGFloat {
        switch quoteText.count {
        case 0..<220: return 48
        case 220..<500: return 40
        default: return 34
        }
    }

    private var watermarkForeground: Color {
        template.foregroundColor
    }
}
