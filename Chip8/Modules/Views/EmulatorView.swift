//
//  EmulatorView.swift
//  Chip8
//
//  Created by Даниил Виноградов on 07.05.2025.
//

import SwiftUI
import UniformTypeIdentifiers

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

    @State private var importFile: Bool = false
    @State private var romData: Data?

    @AppStorage("blackColor") var blackColor: Color = .black
    @AppStorage("whiteColor") var whiteColor: Color = .cyan

    private let ch8Type = UTType(importedAs: "com.xitrix.chip8", conformingTo: .data)

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ColorPicker("Black color", selection: $blackColor)
                    ColorPicker("White color", selection: $whiteColor)
                }

                Section {
                    ForEach(roms) { rom in
                        NavigationLink(rom.title) {
                            let data = try! Data(contentsOf: rom.url)
                            EmulatorView(rom: data, blackColor: $blackColor, whiteColor: $whiteColor)
                                .navigationTitle(rom.title)
                        }
                    }
                    Button {
                        importFile = true
                    } label: {
                        Text("Import ROM")
                    }
                }
            }
            .navigationTitle("Chip-8")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: Binding(
                get: { romData != nil },
                set: { if !$0 { romData = nil } }
            )) {
                if let data = romData {
                    EmulatorView(rom: data, blackColor: $blackColor, whiteColor: $whiteColor)
                }
            }
            .fileImporter(isPresented: $importFile, allowedContentTypes: [ch8Type]) { result in
                switch result {
                case .success(let url):
                    guard url.startAccessingSecurityScopedResource()
                    else { return }
                    defer { url.stopAccessingSecurityScopedResource() }

                    if let data = try? Data(contentsOf: url) {
                        romData = data
                    }
                case .failure(let error):
                    print("File import failed: \(error)")
                }
            }
        }
    }
}

struct EmulatorView: View {
//    let rom: Data
    @State var core: Core
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Binding var blackColor: Color
    @Binding var whiteColor: Color

    init(rom: Data, blackColor: Binding<Color>, whiteColor: Binding<Color>) {
//        self.rom = rom
        _blackColor = blackColor
        _whiteColor = whiteColor
        _core = State(initialValue: Core(rom: rom))
    }

    var body: some View {
        ZStack {
            let emu = PixelImageView(pixels: $core.imageData, blackColor: $blackColor, whiteColor: $whiteColor)
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
        .navigationBarTitleDisplayMode(.inline)
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
