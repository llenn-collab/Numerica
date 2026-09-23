import SwiftUI
import AppKit

extension Color {
    init(_ rgb: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((rgb >> 16) & 0xFF) / 255,
                  green: Double((rgb >> 8) & 0xFF) / 255,
                  blue: Double(rgb & 0xFF) / 255,
                  opacity: opacity)
    }

    init(light: UInt32, dark: UInt32) {
        self.init(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(Color(isDark ? dark : light))
        }))
    }
}

/// Design tokens extracted from Numerology_Calculator.html, constrained to
/// SKILLS/apple_design.md: sans-serif only, system type, critically damped
/// springs, zero scrolling via a window sized exactly to content.
enum Theme {
    // MARK: Palette (light / dark, mirroring the reference's adaptive scheme)
    static let background    = Color(light: 0xEDE7D9, dark: 0x14141C)
    static let ink           = Color(light: 0x1B1E29, dark: 0xEDE7D9)
    static let muted         = Color(light: 0x6B6656, dark: 0xA79F8C)

    // System color-coding: Pythagorean = brass, Chaldean = verdigris.
    static let brass         = Color(light: 0x9C7A34, dark: 0xC9A24B)
    static let verdigris     = Color(light: 0x3E7566, dark: 0x6FA593)

    // Text-safe accent variants (>= 4.5:1 on background) for small glyphs.
    static let brassText     = Color(light: 0x7F6224, dark: 0xC9A24B)
    static let verdigrisText = Color(light: 0x356B5D, dark: 0x6FA593)

    // Hairline rules (spec §12: structure over shadows).
    static var hairline: Color { ink.opacity(0.16) }
    static var hairlineStrong: Color { ink.opacity(0.45) } // prefers-contrast: more

    // MARK: Motion (spec §4): critically damped, no overshoot — no momentum gestures exist.
    static let spring = Animation.spring(response: 0.35, dampingFraction: 1.0)
    static let press  = Animation.spring(response: 0.20, dampingFraction: 1.0)

    // MARK: Window sized exactly to content (zero scrolling).
    static let windowWidth:  CGFloat = 880
    static let windowHeight: CGFloat = 700
}

extension NumerologySystem {
    var accent: Color { self == .pythagorean ? Theme.brass : Theme.verdigris }
    var textAccent: Color { self == .pythagorean ? Theme.brassText : Theme.verdigrisText }
}
