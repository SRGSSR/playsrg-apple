//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CoreMedia
import Foundation
import SRGUserData

#if os(iOS)
    import UserNotifications
#endif

/// Writes a full snapshot of the user's PlaySRG data into the shared App Group container at
/// `<shared group>/<bu>/export.json`, for the Play+ app to read. Idempotent: every run overwrites.
@objc final class UserDataExporter: NSObject {
    @objc static let shared = UserDataExporter()

    /// BUs migrated to Play+. SWI is intentionally excluded (PLAYNEXT-7624) although it joins the
    /// shared group for its notification inbox.
    private static let exportedBusinessUnits: Set<String> = ["srf", "rts", "rsi", "rtr"]

    private let queue = DispatchQueue(label: "ch.srgssr.playsrg.userdataexport", qos: .utility)

    override private init() {
        super.init()
    }

    /// Requests an export. Safe to call from any thread; work is serialized off the main thread.
    @objc func setNeedsExport() {
        queue.async { [weak self] in
            self?.export()
        }
    }

    private func export() {
        guard let businessUnit = FileManager.play_businessUnitIdentifier,
              Self.exportedBusinessUnits.contains(businessUnit),
              let directoryURL = FileManager.play_sharedBusinessUnitContainerURL,
              let userData = SRGUserData.current else {
            return
        }

        let subscriptions = Self.subscriptions(from: userData)

        let group = DispatchGroup()

        var myList: [UserDataExport.PlaylistItem] = []
        group.enter()
        userData.playlists.playlistEntriesInPlaylist(withUid: SRGPlaylistUid.watchLater.rawValue, matching: nil, sortedWith: nil) { entries, _ in
            myList = (entries ?? []).compactMap { entry in
                guard let urn = entry.uid else { return nil }
                return UserDataExport.PlaylistItem(mediaURN: urn, date: Self.milliseconds(from: entry.date))
            }
            group.leave()
        }

        var history: [UserDataExport.HistoryItem] = []
        group.enter()
        userData.history.historyEntries(matching: nil, sortedWith: nil) { entries, _ in
            history = (entries ?? []).compactMap { entry in
                guard let urn = entry.uid else { return nil }
                let seconds = CMTimeGetSeconds(entry.lastPlaybackTime)
                let positionMs = seconds.isFinite ? Int64((seconds * 1000).rounded()) : 0
                return UserDataExport.HistoryItem(mediaURN: urn,
                                                  lastPlaybackPositionMs: positionMs,
                                                  date: Self.milliseconds(from: entry.date),
                                                  deviceUid: entry.deviceUid)
            }
            group.leave()
        }

        #if os(iOS)
            let downloads: [UserDataExport.DownloadItem]? = Download.downloads.compactMap { download in
                guard let urn = download.media?.urn else { return nil }
                return UserDataExport.DownloadItem(mediaURN: urn,
                                                   title: download.media?.title,
                                                   date: Self.milliseconds(from: download.creationDate))
            }

            var pushGranted: Bool? = false // swiftlint:disable:this discouraged_optional_boolean
            group.enter()
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                pushGranted = (settings.authorizationStatus == .authorized)
                group.leave()
            }
        #else
            let downloads: [UserDataExport.DownloadItem]? = nil
            let pushGranted: Bool? = nil // swiftlint:disable:this discouraged_optional_boolean
        #endif

        group.notify(queue: queue) {
            let export = UserDataExport(version: 1,
                                        exportedAt: Self.timestampFormatter.string(from: Date()),
                                        businessUnit: businessUnit,
                                        subscriptions: subscriptions,
                                        myList: myList,
                                        history: history,
                                        downloads: downloads,
                                        pushPermissionGranted: pushGranted)
            Self.write(export, to: directoryURL)
        }
    }

    // MARK: Readers

    private static func subscriptions(from userData: SRGUserData) -> [UserDataExport.Subscription] {
        guard let favorites = userData.preferences.dictionary(atPath: "favorites", inDomain: "play") else {
            return []
        }
        return favorites.compactMap { key, value in
            guard let urn = key as? String, let entry = value as? [String: Any] else { return nil }
            let date = (entry["date"] as? NSNumber)?.int64Value
            let notifications = entry["notifications"] as? [String: Any]
            let enabled = (notifications?["newod"] as? NSNumber)?.boolValue ?? false
            return UserDataExport.Subscription(showURN: urn, date: date, notificationEnabled: enabled)
        }
    }

    private static func milliseconds(from date: Date?) -> Int64? {
        guard let date else { return nil }
        return Int64((date.timeIntervalSince1970 * 1000).rounded())
    }

    // MARK: Writer

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func write(_ export: UserDataExport, to directoryURL: URL) {
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(export)
            try data.write(to: directoryURL.appendingPathComponent("export.json"), options: .atomic)
        } catch {
            assertionFailure("User data export failed: \(error)")
        }
    }
}
