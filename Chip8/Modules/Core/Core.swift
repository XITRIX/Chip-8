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
    var keyboardKeys: [UInt8: Bool] = [:]
    var rom: [UInt8]

    var isVerbose = false
    var memoryNewBehaviour: Bool = true
    var shiftNewBehaviour: Bool = false
    var jumpingNewBehaviour: Bool = true

    init(rom: Data) {
        self.rom = [UInt8](rom)
    }

    func start() {
        pc = 0x200
        index = 0
        stack = []
        reg = [:]
        memory = .init(repeating: 0, count: 4096)
        framebuffer = .init()

        loadFont()
        loadRom()

        // 700
        cpuRunLoop = .init(fps: 30000, name: "cpu") { [weak self] in
            guard let self else { return }

            keyboardKeysCopy = keyboardKeys

            let instruction = fetch()
            decode(instruction)
            execute()

        }

        displayRunLoop = .init(fps: 60, name: "display") { [weak self] in
            guard let self else { return }
            if delayTimer > 0 { delayTimer -= 1 }
            if soundTimer > 0 {
                BeepController.shared.startBeeping()
                soundTimer -= 1
            } else {
                BeepController.shared.stopBeeping()
            }

            if imageData.data != framebuffer.data {
                imageData = framebuffer
            }
        }
    }

    func stop() {
        cpuRunLoop = nil
        displayRunLoop = nil
        BeepController.shared.stopBeeping()
    }

    deinit {
        print("Deinit")
    }

    private var keyToWait: UInt8?
    private var keyboardKeysCopy: [UInt8: Bool] = [:]
    private var displayCall = false
    private var framebuffer: ImageData = .init() {
        didSet { displayCall = true }
    }

    private var pc: UInt16 = 0x200
    private var index: UInt16 = 0
    private var stack: [UInt16] = []
    private var reg: [UInt8: UInt8] = [:]
    private var memory: [UInt8] = .init(repeating: 0, count: 4096)

    private var delayTimer: UInt8 = 0
    private var soundTimer: UInt8 = 0

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
        verbosePrint("Decoding instruction: \(String(format: "%04X", instruction))")
        switch instruction & 0xf000 {
        case 0x0000:
            switch instruction {
            case 0x00e0: // DONE
                framebuffer.clear()
                verbosePrint("Clear display")
            case 0x00ee:
                pc = stack.removeLast()
                verbosePrint("Pop back PC to \(pc)")
            default:
                stub(instruction)
            }
        case 0x1000: // DONE
            pc = instruction & 0x0fff
            verbosePrint("Jump PC to \(pc)")
        case 0x2000:
            stack.append(pc)
            pc = instruction & 0x0fff
            verbosePrint("Subroutine PC to \(pc)")
        case 0x3000:
            skip(instruction)
        case 0x4000:
            skip(instruction)
        case 0x5000:
            skip(instruction)
        case 0x6000: // DONE
            let address = UInt8((instruction & 0x0f00) >> 8)
            let value = UInt8(instruction & 0x00ff)
            reg[address] = value
            verbosePrint("Set V\(address): \(value)")
        case 0x7000: // DONE
            let vx = UInt8((instruction & 0x0f00) >> 8)
            let nn = UInt8(instruction & 0x00ff)
            reg[vx] = (reg[vx] ?? 0) &+ nn
            verbosePrint("Add \(nn) to Reg V\(vx)")
        case 0x8000:
            math(instruction)
        case 0x9000:
            skip(instruction)
        case 0xa000: // DONE
            index = instruction & 0x0fff
            verbosePrint("Set index: \(index)")
        case 0xb000:
            jump(instruction)
        case 0xc000:
            let vx = UInt8((instruction & 0x0f00) >> 8)
            let nn = UInt8(instruction & 0x00ff)
            let rand = UInt8.random(in: 0 ... UInt8.max) & nn
            reg[vx] = rand
            verbosePrint("Random number \(rand) put into Reg V\(vx)")
        case 0xd000: // WORK
            draw(instruction)
        case 0xe000:
            skip(instruction)
        case 0xf000:
            fInstructions(instruction)
        default:
            stub(instruction)
        }
        verbosePrint("")
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
    func jump(_ instruction: UInt16) {
        if !jumpingNewBehaviour {
            index = instruction & 0x0fff + UInt16(reg[0x0] ?? 0)
        } else {
            let vx = UInt8((instruction & 0x0f00) >> 8)
            index = instruction & 0x0fff + UInt16(reg[vx] ?? 0)
        }
    }

    func math(_ instruction: UInt16) {
        let vx = UInt8((instruction & 0x0f00) >> 8)
        let vy = UInt8((instruction & 0x00f0) >> 4)

        let x = reg[vx] ?? 0
        let y = reg[vy] ?? 0

        switch instruction & 0x000f {
        case 0x0000:
            reg[vx] = reg[vy]
            verbosePrint("Set Reg V\(vx) to \(reg[vy]!)")
        case 0x0001:
            reg[vx]! |= y
            reg[0xf] = 0
        case 0x0002:
            reg[vx]! &= y
            reg[0xf] = 0
        case 0x0003:
            reg[vx]! ^= y
            reg[0xf] = 0
        case 0x0004:
            let flag: UInt8 = (Int(x) + Int(y)) > UInt8.max ? 1 : 0
            reg[vx] = x &+ y
            reg[0xf] = flag
        case 0x0005:
            let flag: UInt8 = x >= y ? 1 : 0
            reg[vx]! &-= y
            reg[0xf] = flag
        case 0x0007:
            let flag: UInt8 = y >= x ? 1 : 0
            reg[vx] = y &- x
            reg[0xf] = flag
        case 0x0006, 0x000e:
            if !shiftNewBehaviour {
                reg[vx] = reg[vy]
            }

            if instruction & 0x000f == 0x6 {
                let flag: UInt8 = x & 1
                reg[vx]! >>= 1
                reg[0xf] = flag
            } else {
                let flag: UInt8 = (x >> 7) & 1
                reg[vx]! <<= 1
                reg[0xf] = flag
            }
        default:
            stub(instruction)
        }
    }

    func fInstructions(_ instruction: UInt16) {
        let vx = UInt8((instruction & 0x0f00) >> 8)

        switch instruction & 0xf0ff {
        case 0xf007:
            reg[vx] = delayTimer
            verbosePrint("Get delay timer \(delayTimer)")
        case 0xf015:
            delayTimer = reg[vx]!
            verbosePrint("Set delay timer \(delayTimer)")
        case 0xf018:
            soundTimer = reg[vx]!
            verbosePrint("Set sound timer \(soundTimer)")
        case 0xf01e:
            index += UInt16(reg[vx] ?? 0)
            verbosePrint("Index increased on \(vx) = \(index)")
        case 0xf029:
            index = 0x050 + UInt16(vx)
        case 0xf033:
            let val = reg[vx]!
            memory[Int(index)] = val / 100
            memory[Int(index) + 1] = val % 100 / 10
            memory[Int(index) + 2] = val % 10
            verbosePrint("")
        case 0xf055:
            saveMem(vx)
        case 0xf065:
            loadMem(vx)
        case 0xf00a:
            if keyToWait != nil, keyboardKeysCopy[keyToWait!] != true {
                reg[vx] = keyToWait
                keyToWait = nil
                break
            }

            if keyToWait == nil {
                for key in keyboardKeysCopy {
                    if key.value {
                        keyToWait = key.key
                    }
                }
            }

            pc -= 2
        default:
            stub(instruction)
        }
    }

    func saveMem(_ size: UInt8) {
        for i in 0 ... size {
            if !memoryNewBehaviour {
                memory[Int(index) + Int(i)] = reg[i] ?? 0
            } else {
                memory[Int(index)] = reg[i] ?? 0
                index += 1
            }
        }
        verbosePrint("Memory saved")
    }

    func loadMem(_ size: UInt8) {
        for i in 0 ... size {
            if !memoryNewBehaviour {
                reg[i] = memory[Int(index) + Int(i)]
            } else {
                reg[i] = memory[Int(index)]
                index += 1
            }
        }
        verbosePrint("Memory loaded")
    }

    func skip(_ instruction: UInt16) {
        var positive = false

        switch instruction & 0xf000 {
        case 0x3000:
            positive = true
            fallthrough
        case 0x4000:
            let vx = UInt8((instruction & 0x0f00) >> 8)
            let nn = UInt8(instruction & 0x00ff)
            let rvx = reg[vx] ?? 0

//            guard let rvx = reg[vx] else {
//                error("Register out of bounds")
//                return
//            }

            if positive ? rvx == nn : rvx != nn {
                pc += 2
                verbosePrint("Instruction skiped")
            } else {
                verbosePrint("Instruction NOT skiped")
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
                verbosePrint("Register out of bounds")
                return
            }

            if positive ? rvx == rvy : rvx != rvy {
                pc += 2
                verbosePrint("Instruction skiped")
            } else {
                verbosePrint("Instruction NOT skiped")
            }
        case 0xe000:
            switch instruction & 0x00ff {
            case 0x009e:
                positive = true
                fallthrough
            case 0x00a1:
                let vx = UInt8((instruction & 0x0f00) >> 8)
                let key = reg[vx] ?? 0

                if positive {
                    if keyboardKeysCopy[key] == true {
                        pc += 2
                    }
                } else {
                    if keyboardKeysCopy[key] != true {
                        pc += 2
                    }
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

        let rvx = reg[vx] ?? 0
        let rvy = reg[vy] ?? 0

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

            if y >= framebuffer.height - 1 {
                break
            }
        }
        verbosePrint("Image drawn")
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

    func verbosePrint(_ message: String) {
        if isVerbose {
            print(message)
        }
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
