//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGUserData

/// Signals which can be used to trigger reactive pipelines.
enum Signal {
    static func historyUpdate() -> AnyPublisher<Void, Never> {
        return NotificationCenter.default.publisher(for: .SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)
            .map { _ in }
            .throttle(for: 10, scheduler: RunLoop.main, latest: true)
            .eraseToAnyPublisher()
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
    
    static func contextMenuLaterRemoval() -> AnyPublisher<[Content.Item], Never> {
        return NotificationCenter.default.publisher(for: .didRemoveWatchLaterEntryFromContextMenu)
            .compactMap { $0.userInfo?[ContextMenu.RemovalKey.removedItem] as? Content.Item }
            .scan([Content.Item]()) { $0.appending($1) }
            .eraseToAnyPublisher()
    }
    
    static func contextMenuFavoriteRemoval() -> AnyPublisher<[Content.Item], Never> {
        return NotificationCenter.default.publisher(for: .didRemoveFavoriteFromContextMenu)
            .compactMap { $0.userInfo?[ContextMenu.RemovalKey.removedItem] as? Content.Item }
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
