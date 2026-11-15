//
//  BookImagePipeline.swift
//  Hilo
//
//  Created by Cactu on 12-10-26.
//

import Foundation
import Nuke

enum BookImagePipeline {

    static func configure() {
        var configuration = ImagePipeline.Configuration()

        // Caché en memoria: 50 MB
        ImageCache.shared.costLimit = 50 * 1024 * 1024

        // Caché en disco: 100 MB
        let dataCache = try? DataCache(name: "hilo.book.covers")
        dataCache?.sizeLimit = 100 * 1024 * 1024

        configuration.imageCache = ImageCache.shared
        configuration.dataCache = dataCache
        configuration.dataCachePolicy = .automatic

        ImagePipeline.shared = ImagePipeline(
            configuration: configuration
        )
    }
}

