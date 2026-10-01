//
//  StorageService.swift
//  Hilo
//
//  Created by Cactu on 28-08-26.
//

import Foundation
import Supabase

final class StorageService {

    func uploadAvatar(
        userId: UUID,
        imageData: Data
    ) async throws -> String {

        let path = "\(userId.uuidString.lowercased())/avatar.jpg"

        try await supabase.storage
            .from("avatars")
            .upload(
                path: path,
                file: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }
    
    func getAvatarURL(userId: UUID) throws -> URL {
        let path = "\(userId.uuidString.lowercased())/avatar.jpg"

        return try supabase.storage
            .from("avatars")
            .getPublicURL(path: path)
    }
}
