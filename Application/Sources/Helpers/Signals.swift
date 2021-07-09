//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGUserData

import struct Foundation.Notification

// MARK: Notifications

/**
 *  Internal notifications sent to signal item removal.
 */
private extension Notification.Name {
    static let didRemoveFavorite = Notification.Name("SignalDidRemoveFavoriteNotification")
    static let didRemoveWatchLaterEntry = Notification.Name("SignalDidRemoveWatchLaterEntryNotification")
}

// MARK: Signals which can be used in pipelines

enum Signal {
enum RemovalKey {
        static let removedItem = "SignalRemovedItemKey"
    }

    /**
     *  Emits a signal when the history is updated for some uid or, if omitted, when any history update occurs.
     */
    static func historyUpdate(for uid: String? = nil) -> AnyPublisher<Void, Never> {
        return NotificationCenter.default.publisher(for: .SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)
            .filter { notification in
                guard let uid = uid else { return true }
                if let updatedUids = notification.userInfo?[SRGHistoryEntriesUidsKey] as? Set<String>, updatedUids.contains(uid) {
                    return true
                }
                else {
                    return false
                }
            }
            .throttle(for: 10, scheduler: RunLoop.main, latest: true)
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    /**
     *  Emits a signal when the watch later playlist is updated for some uid or, if omitted, when any watch later update occurs.
     */
    static func watchLaterUpdate(for uid: String? = nil) -> AnyPublisher<Void, Never> {
        return NotificationCenter.default.publisher(for: .SRGPlaylistEntriesDidChange, object: SRGUserData.current?.playlists)
            .filter { notification in
                if let playlistUid = notification.userInfo?[SRGPlaylistUidKey] as? String, playlistUid == SRGPlaylistUid.watchLater.rawValue {
                    guard let uid = uid else { return true }
                    if let updatedUids = notification.userInfo?[SRGPlaylistEntriesUidsKey] as? Set<String>, updatedUids.contains(uid) {
                        return true
                    }
                    else {
                        return false
                    }
                }
                else {
                    return false
                }
            }
            .throttle(for: 10, scheduler: RunLoop.main, latest: true)
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    /**
     *  Emits a signal when the favorite list is updated.
     */
    static func favoritesUpdate() -> AnyPublisher<Void, Never> {
        return NotificationCenter.default.publisher(for: .SRGPreferencesDidChange, object: SRGUserData.current?.preferences)
            .filter { notification in
                if let domains = notification.userInfo?[SRGPreferencesDomainsKey] as? Set<String>, domains.contains(PlayPreferencesDomain) {
                    return true
                }
                else {
                    return false
                }
            }
            .throttle(for: 10, scheduler: RunLoop.main, latest: true)
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    static func watchLaterRemoval() -> AnyPublisher<[Content.Item], Never> {
        return NotificationCenter.default.publisher(for: .didRemoveWatchLaterEntry)
            .compactMap { $0.userInfo?[RemovalKey.removedItem] as? Content.Item }
            .scan([Content.Item]()) { $0.appending($1) }
            .eraseToAnyPublisher()
    }
    
    static func favoritesRemoval() -> AnyPublisher<[Content.Item], Never> {
        return NotificationCenter.default.publisher(for: .didRemoveFavorite)
            .compactMap { $0.userInfo?[RemovalKey.removedItem] as? Content.Item }
            .scan([Content.Item]()) { $0.appending($1) }
            .eraseToAnyPublisher()
    }
    
    /**
     *
     *  Emits a signal when the application is woken up (network reachable again or moved to the foreground).
     */
    static func wokenUp() -> AnyPublisher<Void, Never> {
        return Publishers.Merge(reachable(), foreground())
            .eraseToAnyPublisher()
    }
    
    private static func reachable() -> AnyPublisher<Void, Never> {
        return NotificationCenter.default.publisher(for: .FXReachabilityStatusDidChange)
            .filter { ReachabilityBecameReachable($0) }
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    private static func foreground() -> AnyPublisher<Void, Never> {
        return NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

// MARK: Methods which can be used to declare item removal

extension Signal {
    static func removeLater(for item: Content.Item) {
        guard case .media = item else { return }
        NotificationCenter.default.post(name: .didRemoveWatchLaterEntry, object: nil, userInfo: [
            RemovalKey.removedItem: item
        ])
    }
    
    static func removeFavorite(for item: Content.Item) {
        guard case .show = item else { return }
        NotificationCenter.default.post(name: .didRemoveFavorite, object: nil, userInfo: [
            RemovalKey.removedItem: item
        ])
    }
}
