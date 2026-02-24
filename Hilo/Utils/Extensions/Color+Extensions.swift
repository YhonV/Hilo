//
//  Color+Extensions.swift
//  Hilo
//
//  Created by Yhon Vivas on 08-02-26.
//

import SwiftUI

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double(hex & 0x0000FF) / 255.0
        
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
