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
    
    static func laterUpdate() -> AnyPublisher<Void, Never> {
        return NotificationCenter.default.publisher(for: .SRGPlaylistEntriesDidChange, object: SRGUserData.current?.playlists)
            .filter { notification in
                if let playlistUid = notification.userInfo?[SRGPlaylistUidKey] as? String, playlistUid == SRGPlaylistUid.watchLater.rawValue {
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
    
    static func laterRemoval() -> AnyPublisher<[Content.Item], Never> {
        return NotificationCenter.default.publisher(for: .didRemoveWatchLaterEntry)
            .compactMap { $0.userInfo?[RemovalKey.removedItem] as? Content.Item }
            .scan([Content.Item]()) { $0.appending($1) }
            .eraseToAnyPublisher()
    }
    
    static func favoriteRemoval() -> AnyPublisher<[Content.Item], Never> {
        return NotificationCenter.default.publisher(for: .didRemoveFavorite)
            .compactMap { $0.userInfo?[RemovalKey.removedItem] as? Content.Item }
            .scan([Content.Item]()) { $0.appending($1) }
            .eraseToAnyPublisher()
    }
    
    static func reachable() -> AnyPublisher<Void, Never> {
        return NotificationCenter.default.publisher(for: .FXReachabilityStatusDidChange)
            .filter { ReachabilityBecameReachable($0) }
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    static func foreground() -> AnyPublisher<Void, Never> {
        return NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    static func wokenUp() -> AnyPublisher<Void, Never> {
        return Publishers.Merge(reachable(), foreground())
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
