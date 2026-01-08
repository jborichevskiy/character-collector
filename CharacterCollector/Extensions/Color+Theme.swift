import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let primary = Color(hex: "a78bfa")      // Light purple
    let primaryDark = Color(hex: "8b5cf6")  // Slightly darker purple
    let secondary = Color(hex: "457b9d")
    let accent = Color(hex: "f4a261")
    let background = Color(hex: "1a1a2e")
    let surface = Color(hex: "16213e")
    let surfaceLight = Color(hex: "1f2b47")
    let text = Color(hex: "f1faee")
    let textMuted = Color(hex: "a8dadc")
    let success = Color(hex: "2a9d8f")
    let warning = Color(hex: "e9c46a")
    let danger = Color(hex: "e76f51")
    let cardBackground = Color(hex: "0f0f23")

    // Status badge colors
    let statusNew = Color(hex: "457b9d")      // Blue
    let statusLearning = Color(hex: "e9c46a") // Yellow
    let statusMastered = Color(hex: "2a9d8f") // Green
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
