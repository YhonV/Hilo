import SwiftUI

struct ShareTemplateRecord: Decodable {
    let id: Int
    let name: String
    let config: ShareTemplateConfig
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, config
        case isDefault = "is_default"
    }
}

struct ShareTemplateConfig: Decodable, Hashable {
    let type: String
    let colors: [String]?
    let imagePath: String?
    let overlayColor: String?
    let overlayOpacity: Double?
    let textColor: String?

    enum CodingKeys: String, CodingKey {
        case type, colors
        case imagePath = "image_path"
        case overlayColor = "overlay_color"
        case overlayOpacity = "overlay_opacity"
        case textColor = "text_color"
    }
}

struct ShareTemplateDefinition: Identifiable, Hashable {
    let id: Int
    let name: String
    let config: ShareTemplateConfig
    let isDefault: Bool
    let imageURL: URL?

    var kind: String { config.type.lowercased() }

    var colors: [Color] {
        (config.colors ?? []).compactMap(Color.init(hexString:))
    }

    var icon: String {
        switch kind {
        case "cover_dynamic": return "wand.and.stars"
        case "image": return "photo"
        default: return "paintpalette"
        }
    }

    var title: String {
        name.hasPrefix("quote_template_")
            ? String(localized: String.LocalizationValue(name))
            : name
    }

    var foregroundColor: Color {
        config.textColor.flatMap(Color.init(hexString:)) ?? .white
    }

    init(record: ShareTemplateRecord, imageURL: URL?) {
        id = record.id
        name = record.name
        config = record.config
        isDefault = record.isDefault
        self.imageURL = imageURL
    }

}

extension Color {
    init?(hexString: String) {
        let normalized = hexString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard normalized.count == 6, let value = Int(normalized, radix: 16) else { return nil }
        self.init(hex: value)
    }
}
