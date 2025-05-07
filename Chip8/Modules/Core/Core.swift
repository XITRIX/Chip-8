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
    var imageData: ImageData = .mock()
    var rom: [UInt8]

    init() {
        let romUrl = Bundle.main.url(forResource: "IBMLogo", withExtension: "ch8")!
//        let romUrl = Bundle.main.url(forResource: "br8kout", withExtension: "ch8")!
        rom = [UInt8](try! Data(contentsOf: romUrl))

        cpuRunLoop = .init(fps: 700, name: "cpu") { [self] in
            let instruction = fetch()
            decode(instruction)
            execute()
        }

        displayRunLoop = .init(fps: 60, name: "display") { [self] in
//            imageData = .mock()
        }
    }

    private var pc: Int = 0
    private var index: UInt16 = 0
    private var stack: [UInt16] = []
    private var reg: [UInt8: UInt8] = [:]
    private var memory: [UInt8] = .init(repeating: 0, count: 4096)

    private var cpuRunLoop: RunLoop!
    private var displayRunLoop: RunLoop!
}

private extension Core {
    func fetch() -> UInt16 {
        if pc >= rom.count - 1 { pc = 0 }

        let instruction = UInt16(rom[pc]) << 8 + UInt16(rom[pc + 1])
        pc += 2
        return instruction
    }

    func decode(_ instruction: UInt16) {
        print("Decoding instruction: \(String(format: "%04X", instruction))")
        switch instruction & 0xf000 {
        case 0x0000:
            switch instruction {
            case 0x00e0:
                imageData.clear()
                print("Clear display")
            default:
                stub(instruction)
            }
        case 0x1000:
            stub(instruction)
        case 0x2000:
            stub(instruction)
        case 0x3000:
            stub(instruction)
        case 0x4000:
            stub(instruction)
        case 0x5000:
            stub(instruction)
        case 0x6000:
            let address = UInt8((instruction & 0x0f00) >> 8)
            let value = UInt8(instruction & 0x00ff)
            reg[address] = value
            print("Set V\(address): \(value)")
        case 0x7000:
            stub(instruction)
        case 0x8000:
            stub(instruction)
        case 0xa000:
            index = instruction & 0x0fff
            print("Set index: \(index)")
        case 0xb000:
            stub(instruction)
        case 0xc000:
            stub(instruction)
        case 0xd000:
            draw(instruction)
        case 0xe000:
            draw(instruction)
        case 0xf000:
            draw(instruction)
        default:
            stub(instruction)
        }
        print("")
    }

    func execute() {}

    func stub(_ instruction: UInt16) {
        print("STUB: undecoded instruction: \(String(format: "%04X", instruction))")
    }
}

private extension Core {
    func draw(_ instruction: UInt16) {
        let vx = UInt8((instruction & 0x0f00) >> 8)
        let vy = UInt8((instruction & 0x00f0) >> 4)
        let n = UInt8(instruction & 0x000f)

        let x = reg[vx]! & UInt8(imageData.width - 1)
        let y = reg[vy]! & UInt8(imageData.height - 1)
        reg[0xf] = 0

        for _ in 0 ..< n {}
        print("Pizda ...")
    }

    static var font: [UInt8] {
        [
            0xf0, 0x90, 0x90, 0x90, 0xf0, // 0
            0x20, 0x60, 0x20, 0x20, 0x70, // 1
            0xf0, 0x10, 0xf0, 0x80, 0xf0, // 2
            0xf0, 0x10, 0xf0, 0x10, 0xf0, // 3
            0x90, 0x90, 0xf0, 0x10, 0x10, // 4
            0xf0, 0x80, 0xf0, 0x10, 0xf0, // 5
            0xf0, 0x80, 0xf0, 0x90, 0xf0, // 6
            0xf0, 0x10, 0x20, 0x40, 0x40, // 7
            0xf0, 0x90, 0xf0, 0x90, 0xf0, // 8
            0xf0, 0x90, 0xf0, 0x10, 0xf0, // 9
            0xf0, 0x90, 0xf0, 0x90, 0x90, // A
            0xe0, 0x90, 0xe0, 0x90, 0xe0, // B
            0xf0, 0x80, 0x80, 0x80, 0xf0, // C
            0xe0, 0x90, 0x90, 0x90, 0xe0, // D
            0xf0, 0x80, 0xf0, 0x80, 0xf0, // E
            0xf0, 0x80, 0xf0, 0x80, 0x80 // F
        ]
    }
}
