//
//  PixelImageView.swift
//  Chip8
//
//  Created by Даниил Виноградов on 07.05.2025.
//

import CoreGraphics
import SwiftUICore

extension PixelImageView {
    struct ImageData {
        static var whiteColor: [UInt8] { [100, 210, 224, 255] }
        static var blackColor: [UInt8] { [0, 0, 0, 255] }
        static var randomColor: [UInt8] { [UInt8.random(in: UInt8.min ... UInt8.max), UInt8.random(in: UInt8.min ... UInt8.max), UInt8.random(in: UInt8.min ... UInt8.max), 255] }

        var data: [UInt8]
        var width: Int
        var height: Int

        init() {
            data = []
            width = 0
            height = 0
        }

        init(data: [UInt8], width: Int, height: Int) {
            self.data = data
            self.width = width
            self.height = height
        }

        static func mock() -> ImageData {
            func getRandColor() -> [UInt8] {
                randomColor
//                Bool.random() ? whiteColor : blackColor
            }

            let width = 64
            let height = 32
            let size = width * height

            var image: [UInt8] = []
            for _ in 0 ..< size {
                image += getRandColor()
            }

            return ImageData(data: image, width: width, height: height)
        }
    }
}

struct PixelImageView: View {
    @Binding var pixels: ImageData

    var body: some View {
        if let image = makeCGImage(from: pixels) {
            Image(decorative: image, scale: 1.0, orientation: .up)
                .resizable()
                .interpolation(.none) // Disable smoothing
                .drawingGroup()       // Force rasterization to apply interpolation setting
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "trash")
        }
    }
}

private extension PixelImageView {
    func makeCGImage(from pixelData: ImageData) -> CGImage? {
        let bytesPerPixel = 4
        let bytesPerRow = pixelData.width * bytesPerPixel
        let bitsPerComponent = 8

        guard pixelData.data.count == pixelData.width * pixelData.height * bytesPerPixel else {
            return nil
        }

        return pixelData.data.withUnsafeBytes { ptr in
            guard let context = CGContext(
                data: UnsafeMutableRawPointer(mutating: ptr.baseAddress!),
                width: pixelData.width,
                height: pixelData.height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return nil
            }

            return context.makeImage()
        }
    }
}
