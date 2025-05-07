//
//  FrameTicker.swift
//  Chip8
//
//  Created by Даниил Виноградов on 07.05.2025.
//

import Foundation

class RunLoop {
    private let timer: DispatchSourceTimer
    private let loop: () -> Void
    private let fps: Double
    private let name: String

    init(fps: Int, name: String, _ loop: @escaping () -> Void) {
        self.loop = loop
        self.name = name
        self.fps = Double(fps)
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "com.chip8.runLoop." + name))
        timer.schedule(deadline: .now(), repeating: 1.0 / self.fps) // 60 FPS
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        timer.resume()
    }

    private func tick() {
        loop()
    }

    deinit {
        timer.cancel()
    }
}
