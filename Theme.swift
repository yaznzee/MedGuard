// Theme.swift
// Shared styling for the MedGuard app

import SwiftUI

enum AppTheme {
    static let background = Color(hex: "F7F8FB")
    static let surface = Color.white
    static let ink = Color(hex: "0F172A")
    static let navy = Color(hex: "0B1F3B")
    static let crimson = Color(hex: "B42318")
    static let muted = Color(hex: "64748B")
    static let border = Color(hex: "E2E8F0")
    static let accentSoft = Color(hex: "EEF2F7")
    static let success = Color(hex: "0F766E")
    static let warning = Color(hex: "B45309")
    static let danger = Color(hex: "B42318")
}

enum AppFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.custom("Georgia", size: size).weight(weight)
    }
    
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Avenir Next", size: size).weight(weight)
    }
    
    static func mono(_ size: CGFloat) -> Font {
        Font.custom("Menlo", size: size)
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body(16, weight: .semibold))
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.9 : 1))
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.border.opacity(0.4), lineWidth: 0.5)
            )
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body(16, weight: .semibold))
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(AppTheme.surface)
            .foregroundColor(color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(configuration.isPressed ? 0.7 : 0.4), lineWidth: 1)
            )
    }
}

// MARK: - Color Extension

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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
