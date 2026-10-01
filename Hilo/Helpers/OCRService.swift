//
//  OCRService.swift
//  Hilo
//
//  Created by Cactu on 27-09-26.
//

import Vision
import UIKit

struct OCRService {

    func extraerTexto(from image: UIImage) throws -> String {
        guard let cgImage = image.cgImage else { return "" }

        let request = VNRecognizeTextRequest()

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["es-ES","en-US"]
        request.usesLanguageCorrection = true

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try requestHandler.perform([request])

        guard let observations = request.results else { return "" }

        let lines = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        return lines.joined(separator: "\n")
    }
}
