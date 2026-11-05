import SwiftUI
import Photos
import UIKit
import Nuke

/// A larger, presentation-focused quote card for the library.
///
/// The background is intentionally kept in this component so it can later be
/// replaced by selectable themes or a Metal-backed renderer without changing
/// the library layout.
struct LibraryQuoteHighlightCard: View {
    @Environment(QuoteViewModel.self) private var quoteViewModel
    let quote: Quote
    @State private var selectedTemplate: ShareTemplateDefinition?
    @State private var showsTemplateEditor = false
    @State private var sharePayload: ShareableQuoteImage?
    @State private var saveMessage: String?

    init(quote: Quote) {
        self.quote = quote
        let cachedTemplate = quote.templateId.flatMap { templateID in
            ShareTemplateService.shared.cachedTemplates.first(where: { $0.id == templateID })
        } ?? ShareTemplateService.shared.cachedDefaultTemplate
        _selectedTemplate = State(initialValue: cachedTemplate)
    }

    private var sourceTitle: String {
        let title = quote.bookContext?.book?.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        return title?.isEmpty == false ? title! : String(localized: "quote_unknown_book")
    }

    private var coverURL: String? {
        guard let value = quote.bookContext?.edition?.coverURL,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return value
    }

    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: quote.createdAt) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: quote.createdAt)
        }()

        guard let date else { return "" }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    private var displayQuote: String {
        let value = quote.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count > 120 else { return value }
        return String(value.prefix(117)) + "..."
    }

    private var shareQuote: String {
        quote.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 24, height: 28, alignment: .leading)
                    .accessibilityHidden(true)

                Spacer()

                HStack(spacing: 14) {
                    Button {
                        Task {
                            if let image = await makeShareImage() {
                                sharePayload = ShareableQuoteImage(image: image)
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(String(localized: "quote_share"))

                    Button {
                        if selectedTemplate != nil {
                            showsTemplateEditor = true
                        }
                    } label: {
                        Image(systemName: "paintbrush")
                    }
                    .accessibilityLabel(String(localized: "quote_edit_template"))

                    Button {
                        Task { await saveImageToPhotos() }
                    } label: {
                        Image(systemName: "arrow.down.to.line.compact")
                    }
                    .accessibilityLabel(String(localized: "quote_save_image"))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            }

            Text(displayQuote)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 92, maxHeight: 92, alignment: .topLeading)

            HStack(alignment: .bottom, spacing: 12) {
                HStack(spacing: 10) {
                    if let coverURL {
                        BookCoverView(url: coverURL, width: 34, height: 48)
                    } else {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(.white.opacity(0.16))
                            .frame(width: 34, height: 48)
                            .overlay {
                                Image(systemName: "book.closed")
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                    }

                    Text(sourceTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    if let pageNumber = quote.pageNumber {
                        Text(String(format: String(localized: "reading_page_number"), pageNumber))
                    }
                    if !formattedDate.isEmpty {
                        Text(formattedDate)
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 78, height: 48, alignment: .bottomTrailing)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(height: 48, alignment: .bottom)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(displayQuote)
        .sheet(isPresented: $showsTemplateEditor) {
            Group {
                if let selectedTemplate {
                    QuoteTemplateEditorSheet(
                        selectedTemplate: selectedTemplate,
                        quoteText: displayQuote,
                        sourceTitle: sourceTitle
                    ) { template in
                        self.selectedTemplate = template
                    Task {
                        try? await quoteViewModel.updateQuoteTemplate(quoteId: quote.id, templateId: template.id)
                    }
                    }
                }
            }
            .presentationDetents([.height(500), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $sharePayload) { payload in
            QuoteShareSheet(image: payload.image)
        }
        .alert(String(localized: "quote_save_image"), isPresented: Binding(get: {
            saveMessage != nil
        }, set: { visible in
            if !visible { saveMessage = nil }
        })) {
            Button(String(localized: "common_close"), role: .cancel) {}
        } message: {
            Text(saveMessage ?? "")
        }
        .task {
            guard let templates = try? await ShareTemplateService.shared.getTemplates(),
                  !templates.isEmpty else { return }
            if let savedTemplateID = quote.templateId,
               let savedTemplate = templates.first(where: { $0.id == savedTemplateID }) {
                selectedTemplate = savedTemplate
            } else {
                selectedTemplate = templates.first(where: { $0.isDefault }) ?? templates[0]
            }
        }
    }

    private var cardBackground: AnyView {
        guard let selectedTemplate else {
            return AnyView(genericBackground)
        }

        switch selectedTemplate.kind {
        case "cover_dynamic" where coverURL != nil:
            return AnyView(CoverMetalBackground(coverURL: coverURL))
        case "image":
            return AnyView(imageBackground)
        default:
            return AnyView(templateBackground)
        }
    }

    private func makeShareImage() async -> UIImage? {
        guard let selectedTemplate else { return nil }
        let image = await loadCoverImage()
        let templateImage = await loadTemplateImage()
        let palette = await CoverPalette.colors(for: coverURL)
        let pageText = quote.pageNumber.map {
            String(format: String(localized: "reading_page_number"), $0)
        }
        let content = QuoteShareCardView(
            quoteText: shareQuote,
            sourceTitle: sourceTitle,
            formattedDate: formattedDate,
            pageText: pageText,
            coverImage: image,
            templateImage: templateImage,
            template: selectedTemplate,
            palette: palette
        )
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        return renderer.uiImage
    }

    private func loadCoverImage() async -> UIImage? {
        guard let coverURL else { return nil }
        if let image = BookCoverSource.cachedImage(coverURL) { return image }
        return try? await ImagePipeline.shared.image(for: BookCoverSource.request(coverURL))
    }

    private func loadTemplateImage() async -> UIImage? {
        guard let url = selectedTemplate?.imageURL else { return nil }
        return await loadImage(url: url)
    }

    private func loadImage(url: URL) async -> UIImage? {
        if let cached = ImagePipeline.shared.cache[url]?.image {
            return cached
        }
        return try? await ImagePipeline.shared.image(for: url)
    }

    private func saveImageToPhotos() async {
        guard let image = await makeShareImage() else {
            saveMessage = String(localized: "quote_save_image_error")
            return
        }

        let authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard authorization == .authorized || authorization == .limited else {
            saveMessage = String(localized: "quote_photos_permission_error")
            return
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            saveMessage = String(localized: "quote_save_image_success")
        } catch {
            saveMessage = String(localized: "quote_save_image_error")
        }
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.primaryStrong.opacity(0.72))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.06))
            }
    }

    private var templateBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(LinearGradient(colors: selectedTemplate?.colors ?? [AppColors.surface, AppColors.border], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var genericBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(AppColors.surface)
    }

    @ViewBuilder
    private var imageBackground: some View {
        if let imageURL = selectedTemplate?.imageURL {
            AsyncImage(url: imageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    templateBackground
                }
            }
            .overlay(Color.black.opacity(selectedTemplate?.config.overlayOpacity ?? 0.2))
        } else {
            templateBackground
        }
    }
}

private struct ShareableQuoteImage: Identifiable {
    let image: UIImage
    let id = UUID()
}
