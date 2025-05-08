//
//  KeyboardView.swift
//  Chip8
//
//  Created by Даниил Виноградов on 08.05.2025.
//

import SwiftUI

struct KeyboardView: View {
    @Binding var keysInput: [UInt8: Bool]

    var body: some View {
        VStack {
            HStack {
                KeyboardButton(keysInput: $keysInput, index: 0x1)
                KeyboardButton(keysInput: $keysInput, index: 0x2)
                KeyboardButton(keysInput: $keysInput, index: 0x3)
                KeyboardButton(keysInput: $keysInput, index: 0xC)
            }
            HStack {
                KeyboardButton(keysInput: $keysInput, index: 0x4)
                KeyboardButton(keysInput: $keysInput, index: 0x5)
                KeyboardButton(keysInput: $keysInput, index: 0x6)
                KeyboardButton(keysInput: $keysInput, index: 0xD)
            }
            HStack {
                KeyboardButton(keysInput: $keysInput, index: 0x7)
                KeyboardButton(keysInput: $keysInput, index: 0x8)
                KeyboardButton(keysInput: $keysInput, index: 0x9)
                KeyboardButton(keysInput: $keysInput, index: 0xE)
            }
            HStack {
                KeyboardButton(keysInput: $keysInput, index: 0xA)
                KeyboardButton(keysInput: $keysInput, index: 0x0)
                KeyboardButton(keysInput: $keysInput, index: 0xB)
                KeyboardButton(keysInput: $keysInput, index: 0xF)
            }
        }
    }
}

struct KeyboardButton: View {
    @Binding var keysInput: [UInt8: Bool]
    let index: UInt8

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } label: {
            Text(String(format: "%01X", index))
                .frame(width: 54, height: 54)
        }
        .buttonRepeatBehavior(.enabled)
//        .buttonStyle(.borderedProminent)
        .buttonStyle(TouchTrackingButtonStyle { isPressed in
            keysInput[index] = isPressed
        })
    }
}

struct TouchTrackingButtonStyle: ButtonStyle {
    @GestureState private var isPressed = false
    let action: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title)
            .fontWeight(.semibold)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
            .onChange(of: isPressed) { newValue in
                print("Touch status: \(newValue)") // true on press, false on release
                action(isPressed)
            }
    }
}
