import Foundation
import Supabase

final class AccountDeletionService {
    private struct Request: Encodable {
        let confirmation = "DELETE"
    }

    private struct Response: Decodable {
        let deleted: Bool
    }

    func deleteAccount() async throws {
        let result: Response = try await supabase.functions.invoke(
            "delete-account", options: FunctionInvokeOptions(body: Request())
        )
        guard result.deleted else { throw URLError(.badServerResponse) }
    }
}
