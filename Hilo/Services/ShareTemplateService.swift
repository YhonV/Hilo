import Foundation
import Supabase
import PostgREST
import Storage
import OSLog

final class ShareTemplateService {
    static let shared = ShareTemplateService()
    private let logger = Logger(subsystem: "com.hilo.app", category: "share-templates")
    private(set) var cachedTemplates: [ShareTemplateDefinition] = []

    var cachedDefaultTemplate: ShareTemplateDefinition? {
        cachedTemplates.first(where: { $0.isDefault }) ?? cachedTemplates.first
    }

    func getTemplates() async throws -> [ShareTemplateDefinition] {
        let records: [ShareTemplateRecord] = try await supabase
            .from("share_templates")
            .select("id, name, config, is_default")
            .order("is_default", ascending: false)
            .order("id", ascending: true)
            .execute()
            .value

        let templates = records.map { record in
            let imageURL = record.config.imagePath.flatMap {
                try? supabase.storage.from("share-templates").getPublicURL(path: $0)
            }
            if let imagePath = record.config.imagePath {
                logger.debug("Template \(record.id, privacy: .public) image path: \(imagePath, privacy: .public), URL: \(imageURL?.absoluteString ?? "nil", privacy: .public)")
            }
            return ShareTemplateDefinition(record: record, imageURL: imageURL)
        }
        cachedTemplates = templates
        logger.debug("Loaded \(templates.count, privacy: .public) share templates")
        return templates
    }
}
