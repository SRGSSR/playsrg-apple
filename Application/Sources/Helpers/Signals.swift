//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGUserData

import struct Foundation.Notification

// MARK: Signals for throttled data updates

enum ThrottledSignal {
    /**
     *  Emits a signal when the history is updated for some uid or, if omitted, when any history update occurs.
     */
    static func historyUpdates(for uid: String? = nil) -> AnyPublisher<Void, Never> {
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
    static func watchLaterUpdates(for uid: String? = nil) -> AnyPublisher<Void, Never> {
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
    static func favoriteUpdates() -> AnyPublisher<Void, Never> {
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
}

// MARK: Signals for application events

enum ApplicationSignal {
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

// MARK: Notifications

/**
 *  Internal notifications sent to signal item updates resulting from user interaction.
 */
private extension Notification.Name {
    static let didUpdateFavorites = Notification.Name("UserInteractionDidUpdateFavoritesNotification")
    static let didUpdateHistoryEntries = Notification.Name("UserInteractionDidUpdateHistoryEntriesNotification")
    static let didUpdateWatchLaterEntries = Notification.Name("UserInteractionDidUpdateWatchLaterEntriesNotification")
}

private enum UserInteractionUpdateKey {
    static let addedItems = "UserInteractionAddedItemsKey"
    static let removedItems = "UserInteractionRemovedItemsKey"
}

// MARK: Signals for immediate data updates resulting from user interaction

enum UserInteractionSignal {
    private static func consolidate(items: [Content.Item], with notification: Notification) -> [Content.Item] {
        if let addedItems = notification.userInfo?[UserInteractionUpdateKey.removedItems] as? [Content.Item] {
            return items + addedItems
        }
        else if let removedItems = notification.userInfo?[UserInteractionUpdateKey.addedItems] as? [Content.Item] {
            return Array(Set(items).subtracting(removedItems))
        }
        else {
            return items
        }
    }
    
    static func historyUpdates() -> AnyPublisher<[Content.Item], Never> {
        return NotificationCenter.default.publisher(for: .didUpdateHistoryEntries)
            .scan([Content.Item]()) { consolidate(items: $0, with: $1) }
            .eraseToAnyPublisher()
    }
    
    static func watchLaterUpdates() -> AnyPublisher<[Content.Item], Never> {
        return NotificationCenter.default.publisher(for: .didUpdateWatchLaterEntries)
            .scan([Content.Item]()) { consolidate(items: $0, with: $1) }
            .eraseToAnyPublisher()
    }
    
    static func favoriteUpdates() -> AnyPublisher<[Content.Item], Never> {
        return NotificationCenter.default.publisher(for: .didUpdateFavorites)
            .scan([Content.Item]()) { consolidate(items: $0, with: $1) }
            .eraseToAnyPublisher()
    }
}

// MARK: Methods to notify data updates resulting from user interaction

enum UserInteractionEvent {
    private static func notify(_ name: Notification.Name, for items: [Content.Item], added: Bool) {
        guard !items.isEmpty else { return }
        let key = added ? UserInteractionUpdateKey.addedItems : UserInteractionUpdateKey.removedItems
        NotificationCenter.default.post(name: name, object: nil, userInfo: [
            key: items
        ])
    }
    
    static func addToHistory(_ medias: [SRGMedia]) {
        notify(.didUpdateHistoryEntries, for: medias.map { Content.Item.media($0) }, added: true)
    }
    
    static func removeFromHistory(_ medias: [SRGMedia]) {
        notify(.didUpdateHistoryEntries, for: medias.map { Content.Item.media($0) }, added: false)
    }
    
    static func addToWatchLater(_ medias: [SRGMedia]) {
        notify(.didUpdateWatchLaterEntries, for: medias.map { Content.Item.media($0) }, added: true)
    }
    
    static func removeFromWatchLater(_ medias: [SRGMedia]) {
        notify(.didUpdateFavorites, for: medias.map { Content.Item.media($0) }, added: false)
    }
    
    static func addToFavorites(_ shows: [SRGShow]) {
        notify(.didUpdateFavorites, for: shows.map { Content.Item.show($0) }, added: true)
    }
    
    static func removeFromFavorites(_ shows: [SRGShow]) {
        notify(.didUpdateFavorites, for: shows.map { Content.Item.show($0) }, added: false)
    }
}
