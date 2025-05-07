//
//  Core.swift
//  Chip8
//
//  Created by Даниил Виноградов on 07.05.2025.
//

import Observation
import QuartzCore

@Observable
class Core {
    var imageData: PixelImageView.ImageData = .mock()

    init() {
        runLoop = .init { [self] in
            imageData = .mock()
        }
    }

    private var runLoop: RunLoop!
}
