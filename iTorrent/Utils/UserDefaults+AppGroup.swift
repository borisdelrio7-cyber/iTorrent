//
//  UserDefaults+AppGroup.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 30.06.2024.
//

import Foundation

extension UserDefaults {
    static var itorrentGroup: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // xtool re-signs with "XTL-<team>." prepended to the bundle ID and the App Group
    // ("group.XTL-<team>.itorrent.life-activity"), so derive the same prefix at runtime.
    private static var appGroupID: String {
        let group = "itorrent.life-activity"
        guard let bundleID = Bundle.main.bundleIdentifier, bundleID.hasPrefix("XTL-"),
              let prefix = bundleID.split(separator: ".").first
        else { return "group.\(group)" }
        return "group.\(prefix).\(group)"
    }
}
