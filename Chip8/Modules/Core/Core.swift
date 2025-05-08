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
    var imageData: ImageData = .init()
    var rom: [UInt8]

    init() {
//        let romUrl = Bundle.main.url(forResource: "IBMLogo", withExtension: "ch8")!
        let romUrl = Bundle.main.url(forResource: "br8kout", withExtension: "ch8")!
        rom = [UInt8](try! Data(contentsOf: romUrl))

        loadFont()
        loadRom()

        cpuRunLoop = .init(fps: 700, name: "cpu") { [self] in
            let instruction = fetch()
            decode(instruction)
            execute()
        }

        displayRunLoop = .init(fps: 60, name: "display") { [self] in
            if displayCall {
                imageData = framebuffer
                displayCall = false
            }
        }
    }

    private var displayCall = false
    private var framebuffer: ImageData = .init() {
        didSet { displayCall = true }
    }

    private var pc: UInt16 = 0x200
    private var index: UInt16 = 0
    private var stack: [UInt16] = []
    private var reg: [UInt8: UInt8] = [:]
    private var memory: [UInt8] = .init(repeating: 0, count: 4096)

    private var cpuRunLoop: RunLoop!
    private var displayRunLoop: RunLoop!
}

private extension Core {
    func fetch() -> UInt16 {
        if pc >= memory.count - 1 { pc = 0 }

        let instruction = UInt16(memory[Int(pc)]) << 8 + UInt16(memory[Int(pc) + 1])
        pc += 2
        return instruction
    }

    func decode(_ instruction: UInt16) {
        print("Decoding instruction: \(String(format: "%04X", instruction))")
        switch instruction & 0xf000 {
        case 0x0000:
            switch instruction {
            case 0x00e0:
                framebuffer.clear()
                print("Clear display")
            case 0x00ee:
                pc = stack.removeLast()
                print("Pop back PC to \(pc)")
            default:
                stub(instruction)
            }
        case 0x1000:
            pc = instruction & 0x0fff
            print("Jump PC to \(pc)")
        case 0x2000:
            stack.append(pc)
            pc = instruction & 0x0fff
            print("Subroutine PC to \(pc)")
        case 0x3000:
            skip(instruction)
        case 0x4000:
            skip(instruction)
        case 0x5000:
            skip(instruction)
        case 0x6000:
            let address = UInt8((instruction & 0x0f00) >> 8)
            let value = UInt8(instruction & 0x00ff)
            reg[address] = value
            print("Set V\(address): \(value)")
        case 0x7000:
            let vx = UInt8((instruction & 0x0f00) >> 8)
            let nn = UInt8(instruction & 0x00ff)
            reg[vx] = (reg[vx] ?? 0) &+ nn
            print("Add \(nn) to Reg V\(vx)")
        case 0x8000:
            let vx = UInt8((instruction & 0x0f00) >> 8)
            let vy = UInt8((instruction & 0x00f0) >> 4)
            reg[vx] = reg[vy]

            print("Set Reg V\(vx) to \(reg[vy]!)")
        case 0x9000:
            skip(instruction)
        case 0xa000:
            index = instruction & 0x0fff
            print("Set index: \(index)")
        case 0xb000:
            stub(instruction)
        case 0xc000:
            let vx = UInt8((instruction & 0x0f00) >> 8)
            let nn = UInt8(instruction & 0x00ff)
            let rand = UInt8.random(in: 0...UInt8.max) & nn
            reg[vx] = rand
            print("Random number \(rand) put into Reg V\(vx)")
        case 0xd000:
            draw(instruction)
        case 0xe000:
            skip(instruction)
        case 0xf000:
            stub(instruction)
        default:
            stub(instruction)
        }
        print("")
    }

    func execute() {}

    func stub(_ instruction: UInt16) {
        print("STUB: undecoded instruction: \(String(format: "%04X", instruction))")
    }

    func error(_ message: String) {
        print("ERROR: \(message)")
    }
}

private extension Core {
    func skip(_ instruction: UInt16) {
        var positive = false

        switch instruction & 0xf000 {
        case 0x3000:
            positive = true
            fallthrough
        case 0x4000:
            let vx = UInt8((instruction & 0x0f00) >> 8)
            let nn = UInt8(instruction & 0x00ff)

            guard let rvx = reg[vx] else {
                error("Register out of bounds")
                return
            }
            
            if positive ? rvx == nn : rvx != nn {
                pc += 2
                print("Instruction skiped")
            } else {
                print("Instruction NOT skiped")
            }
        case 0x5000:
            positive = true
            fallthrough
        case 0x9000:
            let vx = UInt8((instruction & 0x0f00) >> 8)
            let vy = UInt8((instruction & 0x00f0) >> 4)

            guard let rvx = reg[vx],
                  let rvy = reg[vy]
            else {
                error("Register out of bounds")
                return
            }

            if positive ? rvx == rvy : rvx != rvy {
                pc += 2
                print("Instruction skiped")
            } else {
                print("Instruction NOT skiped")
            }
        case 0xe000:
            switch instruction & 0x00FF {
            case 0x009e:
                positive = true
                fallthrough
            case 0x00a1:
                let vx = UInt8((instruction & 0x0f00) >> 8)
                error("Keyboard not implemented")

                if positive {
//                    pc += 2
                } else {
                    pc += 2
                }
            default:
                stub(instruction)
            }
        default:
            stub(instruction)
        }
    }

    func draw(_ instruction: UInt16) {
        let vx = UInt8((instruction & 0x0f00) >> 8)
        let vy = UInt8((instruction & 0x00f0) >> 4)
        let n = UInt8(instruction & 0x000f)

        guard let rvx = reg[vx],
              let rvy = reg[vy]
        else {
            error("Register out of bounds")
            return
        }

        let x = rvx & UInt8(framebuffer.width - 1)
        var y = rvy & UInt8(framebuffer.height - 1)
        reg[0xf] = 0

        for offset in 0 ..< n {
            let byte = memory[Int(index) + Int(offset)]
            var x = x
            for bit in byte.bits {
                if bit {
                    if framebuffer.get(x, y) {
                        framebuffer.set(x, y, false)
                        reg[0xf] = 1
                    } else {
                        framebuffer.set(x, y, true)
                    }
                }

                if x == framebuffer.width - 1 {
                    break
                }

                x += 1
            }
            y += 1

            if y == framebuffer.height - 1 {
                break
            }
        }
    }

    func loadFont() {
        let font = Self.font

        for index in (0x050 ..< font.count + 0x050).enumerated() {
            memory[index.element] = font[index.offset]
        }
    }

    func loadRom() {
        for index in (0x200 ..< rom.count + 0x200).enumerated() {
            memory[index.element] = rom[index.offset]
        }
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

extension UInt8 {
    var bits: [Bool] {
        var temp = self
        var res: [Bool] = .init(repeating: false, count: 8)

        for i in 0 ..< 8 {
            res[i] = temp & 1 == 1
            temp >>= 1
        }

        return res.reversed()
    }
}
