import SwiftUI

/// Animated Metal surface whose palette follows a book cover.
struct CoverMetalBackground: View {
    let coverURL: String?

    @State private var palette = CoverPalette.fallback

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            MeshGradient(
                width: 3,
                height: 3,
                points: points(at: time),
                colors: meshColors
            )
            .overlay(Color.black.opacity(0.18))
        }
        .task(id: coverURL) {
            palette = await CoverPalette.colors(for: coverURL)
        }
    }

    private var meshColors: [Color] {
        let first = palette[safe: 0] ?? CoverPalette.fallback[0]
        let second = palette[safe: 1] ?? CoverPalette.fallback[1]
        let third = palette[safe: 2] ?? CoverPalette.fallback[2]
        return [first, first, second, first, second, third, second, third, third]
    }

    private func points(at time: TimeInterval) -> [SIMD2<Float>] {
        let x = Float(sin(time * 0.22) * 0.07)
        let y = Float(cos(time * 0.17) * 0.06)
        return [
            SIMD2(0, 0), SIMD2(0.5 + x, 0), SIMD2(1, 0),
            SIMD2(0, 0.5 + y), SIMD2(0.5 - y, 0.5 + x), SIMD2(1, 0.5 - y),
            SIMD2(0, 1), SIMD2(0.5 - x, 1), SIMD2(1, 1)
        ]
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
