//
//  EmulatorView.swift
//  Chip8
//
//  Created by Даниил Виноградов on 07.05.2025.
//

import SwiftUI

struct Rom: Identifiable {
    var id: URL { url }

    let title: String
    let url: URL
}

struct RomSelectingView: View {
    @State var roms: [Rom] = [
        .init(title: "IBMLogo", url: Bundle.main.url(forResource: "IBMLogo", withExtension: "ch8")!),
        .init(title: "br8kout", url: Bundle.main.url(forResource: "br8kout", withExtension: "ch8")!),
        .init(title: "octojam4title", url: Bundle.main.url(forResource: "octojam4title", withExtension: "ch8")!),
        .init(title: "octojam2title", url: Bundle.main.url(forResource: "octojam2title", withExtension: "ch8")!),
        .init(title: "octojam8title", url: Bundle.main.url(forResource: "octojam8title", withExtension: "ch8")!),
        .init(title: "slipperyslope", url: Bundle.main.url(forResource: "slipperyslope", withExtension: "ch8")!),
        .init(title: "danm8ku", url: Bundle.main.url(forResource: "danm8ku", withExtension: "ch8")!),
        .init(title: "1-chip8-logo", url: Bundle.main.url(forResource: "1-chip8-logo", withExtension: "ch8")!),
        .init(title: "2-ibm-logo", url: Bundle.main.url(forResource: "2-ibm-logo", withExtension: "ch8")!),
        .init(title: "3-corax+", url: Bundle.main.url(forResource: "3-corax+", withExtension: "ch8")!),
        .init(title: "4-flags", url: Bundle.main.url(forResource: "4-flags", withExtension: "ch8")!),
        .init(title: "5-quirks", url: Bundle.main.url(forResource: "5-quirks", withExtension: "ch8")!),
        .init(title: "6-keypad", url: Bundle.main.url(forResource: "6-keypad", withExtension: "ch8")!),
        .init(title: "7-beep", url: Bundle.main.url(forResource: "7-beep", withExtension: "ch8")!),
        .init(title: "8-scrolling", url: Bundle.main.url(forResource: "8-scrolling", withExtension: "ch8")!),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(roms) { rom in
                    NavigationLink(rom.title) {
                        let data = try! Data(contentsOf: rom.url)
                        EmulatorView(rom: data)
                            .navigationTitle(rom.title)
                    }
                }
            }
        }
    }
}

struct EmulatorView: View {
//    let rom: Data
    @State var core: Core
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init(rom: Data) {
//        self.rom = rom
        _core = State(initialValue: Core(rom: rom))
    }

    var body: some View {
        ZStack {
            let emu = PixelImageView(pixels: $core.imageData)
            let keyboard = KeyboardView(keysInput: $core.keyboardKeys)
            
            if horizontalSizeClass == .compact {
                VStack {
                    emu
                    keyboard
                }
            } else {
                HStack {
                    emu
                    keyboard
                }
            }
        }
        .padding()
        .onAppear {
            core.start()
        }
        .onDisappear {
            core.stop()
        }
    }
}

#Preview {
    RomSelectingView()
}
