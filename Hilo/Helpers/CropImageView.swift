//
//  CropImageView.swift
//  Hilo
//
//  Created by Cactu on 27-09-26.
//

import SwiftUI
import UIKit

struct CropImageView: View {

    let image: UIImage

    let onCancel: () -> Void
    let onCrop: (UIImage) -> Void

    @State private var cropRect: CGRect = .zero
    @State private var imageFrame: CGRect = .zero

    @State private var dragStartRect: CGRect?
    @State private var resizeStartRect: CGRect?

    private let minimumCropSize: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {

            GeometryReader { geometry in

                let frame = aspectFitFrame(
                    imageSize: image.size,
                    containerSize: geometry.size
                )

                ZStack {
                    Color.black

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: frame.width,
                            height: frame.height
                        )
                        .position(
                            x: frame.midX,
                            y: frame.midY
                        )

                    if cropRect != .zero {

                        // Oscurecer todo excepto la selección
                        Path { path in
                            path.addRect(frame)
                            path.addRect(cropRect)
                        }
                        .fill(
                            Color.black.opacity(0.55),
                            style: FillStyle(eoFill: true)
                        )

                        // Rectángulo de selección
                        Rectangle()
                            .stroke(.white, lineWidth: 2)
                            .frame(
                                width: cropRect.width,
                                height: cropRect.height
                            )
                            .position(
                                x: cropRect.midX,
                                y: cropRect.midY
                            )
                            .contentShape(Rectangle())
                            .gesture(
                                moveGesture(in: frame)
                            )

                        // Control para cambiar tamaño
                        ZStack {
                            Color.clear

                            Circle()
                                .fill(.white)
                                .frame(width: 22, height: 22)
                                .shadow(radius: 2)
                        }
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                        .position(
                            x: cropRect.maxX,
                            y: cropRect.maxY
                        )
                        .highPriorityGesture(
                            resizeGesture(in: frame)
                        )
                    }
                }
                .onAppear {
                    imageFrame = frame

                    if cropRect == .zero {
                        initializeCropRect(in: frame)
                    }
                }
                .onChange(of: geometry.size) {
                    imageFrame = frame
                }
            }

            // MARK: - Acciones

            HStack {
                Button("Cancelar") {
                    onCancel()
                }

                Spacer()

                Button("Usar selección") {
                    guard let croppedImage = cropImage() else {
                        return
                    }

                    onCrop(croppedImage)
                }
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(.black)
    }

    // MARK: - Posición inicial

    private func initializeCropRect(in imageFrame: CGRect) {
        let width = imageFrame.width * 0.85
        let height = imageFrame.height * 0.35

        cropRect = CGRect(
            x: imageFrame.midX - width / 2,
            y: imageFrame.midY - height / 2,
            width: width,
            height: height
        )
    }

    // MARK: - Mover selección

    private func moveGesture(
        in imageFrame: CGRect
    ) -> some Gesture {

        DragGesture()
            .onChanged { value in

                if dragStartRect == nil {
                    dragStartRect = cropRect
                }

                guard let startRect = dragStartRect else {
                    return
                }

                var newRect = startRect.offsetBy(
                    dx: value.translation.width,
                    dy: value.translation.height
                )

                newRect.origin.x = min(
                    max(newRect.origin.x, imageFrame.minX),
                    imageFrame.maxX - newRect.width
                )

                newRect.origin.y = min(
                    max(newRect.origin.y, imageFrame.minY),
                    imageFrame.maxY - newRect.height
                )

                cropRect = newRect
            }
            .onEnded { _ in
                dragStartRect = nil
            }
    }

    // MARK: - Redimensionar selección

    private func resizeGesture(
        in imageFrame: CGRect
    ) -> some Gesture {

        DragGesture()
            .onChanged { value in

                if resizeStartRect == nil {
                    resizeStartRect = cropRect
                }

                guard let startRect = resizeStartRect else {
                    return
                }

                var newWidth =
                    startRect.width + value.translation.width

                var newHeight =
                    startRect.height + value.translation.height

                newWidth = max(
                    newWidth,
                    minimumCropSize
                )

                newHeight = max(
                    newHeight,
                    minimumCropSize
                )

                newWidth = min(
                    newWidth,
                    imageFrame.maxX - startRect.minX
                )

                newHeight = min(
                    newHeight,
                    imageFrame.maxY - startRect.minY
                )

                cropRect = CGRect(
                    x: startRect.minX,
                    y: startRect.minY,
                    width: newWidth,
                    height: newHeight
                )
            }
            .onEnded { _ in
                resizeStartRect = nil
            }
    }

    // MARK: - Recortar UIImage

    private func cropImage() -> UIImage? {

        let normalizedImage = image.normalized()

        guard let cgImage = normalizedImage.cgImage,
              imageFrame.width > 0,
              imageFrame.height > 0 else {
            return nil
        }

        let scaleX =
            CGFloat(cgImage.width) / imageFrame.width

        let scaleY =
            CGFloat(cgImage.height) / imageFrame.height

        let cropX =
            (cropRect.minX - imageFrame.minX) * scaleX

        let cropY =
            (cropRect.minY - imageFrame.minY) * scaleY

        let cropWidth =
            cropRect.width * scaleX

        let cropHeight =
            cropRect.height * scaleY

        let pixelRect = CGRect(
            x: cropX,
            y: cropY,
            width: cropWidth,
            height: cropHeight
        ).integral

        guard let croppedCGImage =
                cgImage.cropping(to: pixelRect) else {
            return nil
        }

        return UIImage(
            cgImage: croppedCGImage,
            scale: normalizedImage.scale,
            orientation: .up
        )
    }

    // MARK: - Frame de imagen

    private func aspectFitFrame(
        imageSize: CGSize,
        containerSize: CGSize
    ) -> CGRect {

        let imageRatio =
            imageSize.width / imageSize.height

        let containerRatio =
            containerSize.width / containerSize.height

        let size: CGSize

        if imageRatio > containerRatio {
            let width = containerSize.width
            let height = width / imageRatio

            size = CGSize(
                width: width,
                height: height
            )
        } else {
            let height = containerSize.height
            let width = height * imageRatio

            size = CGSize(
                width: width,
                height: height
            )
        }

        return CGRect(
            x: (containerSize.width - size.width) / 2,
            y: (containerSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }
}

extension UIImage {

    func normalized() -> UIImage {

        guard imageOrientation != .up else {
            return self
        }

        let renderer = UIGraphicsImageRenderer(
            size: size
        )

        return renderer.image { _ in
            draw(
                in: CGRect(
                    origin: .zero,
                    size: size
                )
            )
        }
    }
}
