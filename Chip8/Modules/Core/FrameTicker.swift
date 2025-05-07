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

    init(_ loop: @escaping () -> Void) {
        self.loop = loop
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "com.chip8.runLoop"))
        timer.schedule(deadline: .now(), repeating: 1.0 / 60.0) // 60 FPS
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
