import SwiftUI
import CoreImage.CIFilterBuiltins
import Nuke
import UIKit

/// Loads a cover through the shared image pipeline and extracts a small palette.
/// The pipeline cache is checked first so the quote background does not create
/// an additional download when the cover is already on screen.
enum CoverPalette {
    private static var cachedPalettes: [String: [Color]] = [:]
    static let fallback: [Color] = [
        Color(red: 0.26, green: 0.32, blue: 0.29),
        Color(red: 0.46, green: 0.28, blue: 0.31),
        Color(red: 0.20, green: 0.23, blue: 0.25)
    ]

    static func colors(for coverURL: String?) async -> [Color] {
        guard let coverURL else {
            return fallback
        }

        let request = BookCoverSource.request(coverURL)
        guard let key = request.url?.absoluteString else {
            return fallback
        }
        if let colors = cachedPalettes[key] { return colors }

        let image: UIImage?
        if let cachedImage = ImagePipeline.shared.cache[request]?.image {
            image = cachedImage
        } else {
            image = try? await ImagePipeline.shared.image(for: request)
        }

        guard let image else { return fallback }
        let colors = extract(from: image)
        if cachedPalettes.count >= 200 { cachedPalettes.removeAll() }
        cachedPalettes[key] = colors
        return colors
    }

    private static func extract(from image: UIImage) -> [Color] {
        guard let ciImage = CIImage(image: image) else { return fallback }

        let maxDimension: CGFloat = 180
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let resizedCI = CIImage(image: resized) else { return fallback }

        let context = CIContext()
        let extent = resizedCI.extent
        let sliceHeight = extent.height / 3
        let colors = (0..<3).compactMap { index -> Color? in
            let rect = CGRect(
                x: extent.minX,
                y: extent.maxY - CGFloat(index + 1) * sliceHeight,
                width: extent.width,
                height: sliceHeight
            )
            let filter = CIFilter.areaAverage()
            filter.inputImage = resizedCI
            filter.extent = rect

            guard let output = filter.outputImage else { return nil }
            var bytes = [UInt8](repeating: 0, count: 4)
            context.render(
                output,
                toBitmap: &bytes,
                rowBytes: 4,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: CGColorSpaceCreateDeviceRGB()
            )
            return Color(
                red: Double(bytes[0]) / 255,
                green: Double(bytes[1]) / 255,
                blue: Double(bytes[2]) / 255
            )
        }

        return colors.count == 3 ? colors : fallback
    }
}
