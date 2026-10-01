//
//  ImageGradient.swift
//  Hilo
//
//  Created by Cactu on 02-09-26.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ImageGradient: View {

    var image: UIImage?
    var count: Int = 3
    var animation: Animation? = .none

    var startPoint: UnitPoint = .top
    var endPoint: UnitPoint = .bottom
    var overlayOpacity: Double = 0.35
    var saturation: Double = 1.0

    var onFinished: ([Color]) -> () = { _ in }

    @State private var colors: [Color] = []

    var body: some View {

        Rectangle()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .saturation(saturation)
            .overlay {
                Color.black.opacity(overlayOpacity)
            }
            .onAppear {
                guard let image else { return }
                updateFor(image: image)
            }
            .onChange(of: image) { oldValue, newValue in
                guard let newImage = newValue else { return }
                updateFor(image: newImage)
            }
    }

    private func updateFor(image: UIImage) {

        let downsizedImage = downsize(image: image)
        let extractedColors = extractColors(image: downsizedImage)

        self.colors = extractedColors
        onFinished(extractedColors)
    }

    private func downsize(image: UIImage) -> UIImage {

        let maxDimension: CGFloat = 200
        let imageSize = image.size

        let scale = maxDimension / max(
            imageSize.width,
            imageSize.height
        )

        let newSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        let renderFormat = UIGraphicsImageRendererFormat()
        renderFormat.scale = 1

        return UIGraphicsImageRenderer(
            size: newSize,
            format: renderFormat
        ).image { _ in

            image.draw(
                in: .init(
                    origin: .zero,
                    size: newSize
                )
            )
        }
    }

    private func extractColors(image: UIImage) -> [Color] {

        guard let ciImage = CIImage(image: image) else {
            return []
        }

        let extent = ciImage.extent
        let tileHeight = extent.height / CGFloat(count)

        let context = CIContext()

        var colors: [Color] = []

        for index in 0..<count {

            let cropRect = CGRect(
                x: extent.origin.x,
                y: extent.height - CGFloat(index + 1) * tileHeight,
                width: image.size.width,
                height: tileHeight
            )

            let filter = CIFilter.areaAverage()

            filter.inputImage = ciImage
            filter.extent = cropRect

            guard let outputImage = filter.outputImage else {
                continue
            }

            var bytes = [UInt8](repeating: 0, count: 4)

            context.render(
                outputImage,
                toBitmap: &bytes,
                rowBytes: 4,
                bounds: .init(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: CGColorSpaceCreateDeviceRGB()
            )

            let color = Color(
                red: CGFloat(bytes[0]) / 255,
                green: CGFloat(bytes[1]) / 255,
                blue: CGFloat(bytes[2]) / 255,
                opacity: CGFloat(bytes[3]) / 255
            )

            colors.append(color)
        }

        return colors
    }
}
#Preview {
    ImageGradient()
}
