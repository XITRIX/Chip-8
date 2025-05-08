//
//  Color+Storage.swift
//  Chip8
//
//  Created by Даниил Виноградов on 09.05.2025.
//

import Foundation
import SwiftUI
import UIKit

extension Color: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else {
            self = .black
            return
        }

        do {
            let color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor ?? .black
            self = Color(color)
        } catch {
            self = .black
        }
    }

    public var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(self), requiringSecureCoding: false) as Data
            return data.base64EncodedString()

        } catch {
            return ""
        }
    }
}
