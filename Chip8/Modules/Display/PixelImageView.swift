//
//  PixelImageView.swift
//  Chip8
//
//  Created by Даниил Виноградов on 07.05.2025.
//

import CoreGraphics
import SwiftUICore

struct ImageData {
//    static var whiteColor: [UInt8] { [100, 210, 224, 255] }
//    static var blackColor: [UInt8] { [0, 0, 0, 255] }
    static var randomColor: [UInt8] { [UInt8.random(in: UInt8.min ... UInt8.max), UInt8.random(in: UInt8.min ... UInt8.max), UInt8.random(in: UInt8.min ... UInt8.max), 255] }
    private let queue = DispatchQueue(label: "Atomic-\(UUID())")

    var data: [Bool]
    var width: Int
    var height: Int

    init(width: Int = 64, height: Int = 32) {
        data = .init(repeating: false, count: width * height)
        self.width = width
        self.height = height
    }

    init(data: [Bool], width: Int, height: Int) {
        self.data = data
        self.width = width
        self.height = height
    }

    func get(_ x: UInt8, _ y: UInt8) -> Bool {
        data[width * Int(y) + Int(x)]
    }

    mutating func set(_ x: UInt8, _ y: UInt8, _ value: Bool) {
        data[width * Int(y) + Int(x)] = value
    }

    mutating func clear() {
        let size = width * height
        data = .init(repeating: false, count: size)
    }

    static func mock() -> ImageData {
        let width = 64
        let height = 32
        let size = width * height

        var image: [Bool] = []
        for _ in 0 ..< size {
            image.append(Bool.random())
        }

        return ImageData(data: image, width: width, height: height)
    }
}

struct PixelImageView: View {
    @Environment(\.self) private var environment

    @Binding var pixels: ImageData
    @Binding var blackColor: Color
    @Binding var whiteColor: Color

    var body: some View {
        if let image = makeCGImage(from: pixels) {
            Image(decorative: image, scale: 1.0, orientation: .up)
                .resizable()
                .interpolation(.none) // Disable smoothing
                .drawingGroup() // Force rasterization to apply interpolation setting
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

        let whiteColor = whiteColor.resolve(in: environment)
        let blackColor = blackColor.resolve(in: environment)

        var data = [UInt8]()
        data.reserveCapacity(pixelData.width * pixelData.height * 4)
        for pixel in pixelData.data {
            data.append(contentsOf: pixel ? whiteColor.data : blackColor.data)
        }

        guard data.count == pixelData.width * pixelData.height * bytesPerPixel else {
            return nil
        }

        return data.withUnsafeBytes { ptr in
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

private extension Color.Resolved {
    var data: [UInt8] {
        [clamp(red), clamp(green), clamp(blue), 255]
    }

    private func clamp(_ x: Float) -> UInt8 {
        UInt8(max(0, min(255, Int((x * 255).rounded()))))
    }
}
