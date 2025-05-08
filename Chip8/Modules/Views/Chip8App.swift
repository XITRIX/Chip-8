//
//  Chip8App.swift
//  Chip8
//
//  Created by Даниил Виноградов on 07.05.2025.
//

import SwiftUI

@main
struct Chip8App: App {
    var body: some Scene {
        WindowGroup {
            RomSelectingView()
        }
    }
}
