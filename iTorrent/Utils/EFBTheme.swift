//
//  EFBTheme.swift
//  iTorrent
//
//  Cockpit / EFB look: one place for every color and the numeric font.
//

import LibTorrent
import SwiftUI

enum EFBTheme {
    /// Labels and names (cockpit white).
    static let primaryText = Color(red: 0.91, green: 0.93, blue: 0.94) // #E8ECEF
    /// Secondary information (light gray).
    static let secondaryText = Color(red: 0.60, green: 0.64, blue: 0.68) // #9AA4AD
    /// Selected values, seeding and interactive elements. Same value as the AccentColor asset.
    static let cyan = Color(red: 0.20, green: 0.84, blue: 0.94) // #33D6F0
    /// Active / normal operation (downloading, progress).
    static let green = Color(red: 0.29, green: 0.89, blue: 0.42) // #4BE36B
    /// Caution: something needs attention.
    static let amber = Color(red: 1.00, green: 0.69, blue: 0.13) // #FFB020
    /// Warning: errors and destructive actions.
    static let red = Color(red: 1.00, green: 0.30, blue: 0.30) // #FF4D4D

    /// SF Mono for numbers (speeds, sizes, percentages, times): every digit has the same width,
    /// so values don't jump around while they update.
    static func numbers(_ style: Font.TextStyle) -> Font {
        .system(style, design: .monospaced)
    }
}

extension TorrentHandle.State {
    /// Green = active, cyan = seeding, amber = needs attention, white/gray = idle or transient.
    var efbColor: Color {
        switch self {
        case .downloading: EFBTheme.green
        case .seeding: EFBTheme.cyan
        case .finished: EFBTheme.primaryText
        case .storageError: EFBTheme.amber
        default: EFBTheme.secondaryText
        }
    }
}
