//
//  ContentView.swift
//  Chip8
//
//  Created by Даниил Виноградов on 07.05.2025.
//

import SwiftUI

struct ContentView: View {
    @State var core = Core()

    var body: some View {
        VStack {
            Text("Chip8 Emulator")
            PixelImageView(pixels: $core.imageData)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
