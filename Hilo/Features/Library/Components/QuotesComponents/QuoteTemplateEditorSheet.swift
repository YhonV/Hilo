import SwiftUI
import OSLog

struct QuoteTemplateEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ShareTemplateDefinition
    @State private var templates: [ShareTemplateDefinition] = []

    let quoteText: String
    let sourceTitle: String
    let onSave: (ShareTemplateDefinition) -> Void
    private let logger = Logger(subsystem: "com.hilo.app", category: "share-templates")

    init(selectedTemplate: ShareTemplateDefinition, quoteText: String, sourceTitle: String, onSave: @escaping (ShareTemplateDefinition) -> Void) {
        _selectedTemplate = State(initialValue: selectedTemplate)
        self.quoteText = quoteText
        self.sourceTitle = sourceTitle
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "quote_template_title"))
                .font(.title3.bold())

            QuoteTemplatePreview(template: selectedTemplate, quoteText: quoteText, sourceTitle: sourceTitle)
                .frame(height: 188)

            ScrollView(.horizontal, showsIndicators: false) {
                if templates.isEmpty {
                    Text(String(localized: "quote_templates_unavailable"))
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                } else {
                    LazyHStack(spacing: 12) {
                        ForEach(templates) { template in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTemplate = template
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    templatePreviewBackground(template)
                                        .frame(width: 78, height: 68)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay { Image(systemName: template.icon).foregroundStyle(.white.opacity(0.9)) }
                                        .overlay {
                                            if selectedTemplate == template {
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(AppColors.accent, lineWidth: 3)
                                            }
                                        }

                                    Text(template.title)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(AppColors.primaryStrong)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.85)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 90, height: 28, alignment: .top)
                                }
                                .frame(width: 92, height: 104, alignment: .top)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(height: 116)
            .padding(.vertical, 4)

            Button(String(localized: "common_save")) {
                onSave(selectedTemplate)
                dismiss()
            }
            .buttonStyle(.glassProminent)
            .tint(AppColors.accent)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .padding(.top, 14)
        .task {
            do {
                let remoteTemplates = try await ShareTemplateService.shared.getTemplates()
                templates = remoteTemplates

                // Keep the current selection, but refresh its config and image URL
                // from the database when the editor is opened again.
                if let refreshedSelection = remoteTemplates.first(where: { $0.id == selectedTemplate.id }) {
                    selectedTemplate = refreshedSelection
                }
            } catch {
                logger.error("Could not load share templates: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func previewColors(for template: ShareTemplateDefinition) -> [Color] {
        template.colors.isEmpty ? [AppColors.primaryStrong, AppColors.accent] : template.colors
    }

    @ViewBuilder
    private func templatePreviewBackground(_ template: ShareTemplateDefinition) -> some View {
        if let imageURL = template.imageURL {
            AsyncImage(url: imageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if case .failure = phase {
                    gradientPreview(for: template)
                } else {
                    ZStack {
                        gradientPreview(for: template)
                        ProgressView().tint(.white)
                    }
                }
            }
        } else {
            gradientPreview(for: template)
        }
    }

    private func gradientPreview(for template: ShareTemplateDefinition) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LinearGradient(colors: previewColors(for: template), startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

private struct QuoteTemplatePreview: View {
    let template: ShareTemplateDefinition
    let quoteText: String
    let sourceTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "quote_opening_mark"))
                .font(.system(size: 32, weight: .bold, design: .serif))
            Text(quoteText)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .lineLimit(3)
            Spacer(minLength: 2)
            Text(sourceTitle)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            if let imageURL = template.imageURL {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        previewGradient
                    }
                }
            } else {
                previewGradient
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var previewGradient: some View {
        LinearGradient(
            colors: template.colors.isEmpty ? [AppColors.primaryStrong, AppColors.accent] : template.colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
