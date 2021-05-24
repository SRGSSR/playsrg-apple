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
        return NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)
            .map { _ in }
            .throttle(for: 10, scheduler: RunLoop.main, latest: true)
            .eraseToAnyPublisher()
    }
    
    static func laterUpdate() -> AnyPublisher<Void, Never> {
        return NotificationCenter.default.publisher(for: Notification.Name.SRGPlaylistEntriesDidChange, object: SRGUserData.current?.playlists)
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
        return NotificationCenter.default.publisher(for: Notification.Name.SRGPreferencesDidChange, object: SRGUserData.current?.preferences)
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
