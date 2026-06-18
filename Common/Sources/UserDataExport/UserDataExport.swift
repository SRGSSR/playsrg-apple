//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

/// JSON contract written into the shared App Group container for the Play+ app to read.
///
/// `downloads` and `pushPermissionGranted` are iOS-only and are omitted from the JSON on tvOS
/// (optional properties encode via `encodeIfPresent`, so `nil` keys are not written).
struct UserDataExport: Encodable {
    let version: Int
    let exportedAt: String
    let businessUnit: String
    let subscriptions: [Subscription]
    let myList: [PlaylistItem]
    let history: [HistoryItem]
    let downloads: [DownloadItem]?
    let pushPermissionGranted: Bool? // swiftlint:disable:this discouraged_optional_boolean

    /// Favorites (Puma `SUBSCRIPTIONS`); `notificationEnabled` maps to Puma `NOTIFICATIONS`.
    struct Subscription: Encodable {
        let showURN: String
        let date: Int64?
        let notificationEnabled: Bool
    }

    /// Watch-later (Puma `MY_LIST`).
    struct PlaylistItem: Encodable {
        let mediaURN: String
        let date: Int64?
    }

    /// Playback history (Puma `watchHistory`).
    struct HistoryItem: Encodable {
        let mediaURN: String
        let lastPlaybackPositionMs: Int64
        let date: Int64?
        let deviceUid: String?
    }

    /// Download metadata only — no media files (Puma `DOWNLOADS`). iOS only.
    struct DownloadItem: Encodable {
        let mediaURN: String
        let title: String?
        let date: Int64?
    }
}
