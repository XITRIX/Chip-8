//
//  BeepController.swift
//  Chip8
//
//  Created by Даниил Виноградов on 08.05.2025.
//

import AVFoundation

class BeepController {
    private var audioPlayer: AVAudioPlayer?
    private var isBeeping = false

    static let shared = BeepController()

    func startBeeping() {
        guard !isBeeping else { return }

        if let url = Bundle.main.url(forResource: "beep", withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1  // Loop indefinitely
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                isBeeping = true
            } catch {
                print("Error playing beep sound: \(error)")
            }
        }
    }

    func stopBeeping() {
        audioPlayer?.stop()
        isBeeping = false
    }
}
