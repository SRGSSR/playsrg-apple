//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct UserDataExport: Encodable {
    let version: Int
    let exportedAt: String
    let businessUnit: String
    let subscriptions: [Subscription]
    let myList: [PlaylistItem]
    let history: [HistoryItem]
    let downloads: [DownloadItem]?
    let pushPermissionGranted: Bool? // swiftlint:disable:this discouraged_optional_boolean

    struct Subscription: Encodable {
        let showURN: String
        let date: Int64?
        let notificationEnabled: Bool
    }

    struct PlaylistItem: Encodable {
        let mediaURN: String
        let date: Int64?
    }

    struct HistoryItem: Encodable {
        let mediaURN: String
        let lastPlaybackPositionMs: Int64
        let date: Int64?
        let deviceUid: String?
    }

    struct DownloadItem: Encodable {
        let mediaURN: String
        let title: String?
        let date: Int64?
    }
}
