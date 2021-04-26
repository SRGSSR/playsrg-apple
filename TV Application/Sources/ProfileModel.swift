//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SwiftUI
import SRGAnalytics
import SRGUserData

class ProfileModel: ObservableObject {
    @Published private(set) var isLoggedIn = false
    @Published private(set) var account: SRGAccount?
    
    private(set) var hasHistoryEntries = false {
        willSet {
            if hasHistoryEntries != newValue {
                objectWillChange.send()
            }
        }
    }
    
    private(set) var hasFavorites = false {
        willSet {
            if hasFavorites != newValue {
                objectWillChange.send()
            }
        }
    }
    
    private(set) var hasWatchLaterItems = false {
        willSet {
            if hasWatchLaterItems != newValue {
                objectWillChange.send()
            }
        }
    }
    
    @Published private(set) var synchronizationDate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceUserDidCancelLogin, object: SRGIdentityService.current)
            .sink { _ in
                self.updateIdentityInformation()
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceUserDidLogin, object: SRGIdentityService.current)
            .sink { _ in
                self.updateIdentityInformation()
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceDidUpdateAccount, object: SRGIdentityService.current)
            .sink { _ in
                self.updateIdentityInformation()
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceUserDidLogout, object: SRGIdentityService.current)
            .sink { _ in
                self.updateIdentityInformation()
            }
            .store(in: &cancellables)
        updateIdentityInformation()
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGUserDataDidFinishSynchronization, object: SRGUserData.current)
            .sink { _ in
                self.updateSynchronizationDate()
            }
            .store(in: &cancellables)
        updateSynchronizationDate()
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)
            .sink { _ in
                self.updateHistoryInformation()
            }
            .store(in: &cancellables)
        updateHistoryInformation()
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGPlaylistEntriesDidChange, object: SRGUserData.current?.playlists)
            .sink { notification in
                guard let playlistUid = notification.userInfo?[SRGPlaylistUidKey] as? String, playlistUid == SRGPlaylistUid.watchLater.rawValue else { return }
                self.updateWatchLaterInformation()
            }
            .store(in: &cancellables)
        updateWatchLaterInformation()
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGPreferencesDidChange, object: SRGUserData.current?.preferences)
            .sink { notification in
                guard let domains = notification.userInfo?[SRGPreferencesDomainsKey] as? Set<String>, domains.contains(PlayPreferencesDomain) else { return }
                self.updateFavoritesInformation()
            }
            .store(in: &cancellables)
        updateFavoritesInformation()
    }
    
    var supportsLogin: Bool {
        return SRGIdentityService.current != nil
    }
    
    var username: String? {
        return account?.displayName ?? SRGIdentityService.current?.emailAddress
    }
    
    var version: String {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? ""
        let bundleNameSuffix = Bundle.main.infoDictionary!["BundleNameSuffix"] as? String ?? ""
        let buildName = Bundle.main.infoDictionary!["BuildName"] as? String ?? ""
        let buildString = Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? ""
        return String(format: "%@%@%@ (%@)", appVersion, bundleNameSuffix.count > 0 ? " " + bundleNameSuffix : "", buildName.count > 0 ? " " + buildName : "", buildString)
    }
    
    func login() {
        if let opened = SRGIdentityService.current?.login(withEmailAddress: nil), opened {
            SRGAnalyticsTracker.shared.trackPageView(withTitle: AnalyticsPageTitle.login.rawValue, levels: [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.user.rawValue])
            
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.type = AnalyticsType.actionDisplayLogin.rawValue
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.identity.rawValue, labels: labels)
        }
    }
    
    func logout() {
        SRGIdentityService.current?.logout()
    }
    
    func removeHistory() {
        SRGUserData.current?.history.discardHistoryEntries(withUids: nil, completionBlock: nil)
    }
    
    func removeFavorites() {
        FavoritesRemoveShows(nil)
    }
    
    func removeWatchLaterItems() {
        SRGUserData.current?.playlists.discardPlaylistEntries(withUids: nil, fromPlaylistWithUid: SRGPlaylistUid.watchLater.rawValue, completionBlock: nil)
    }
    
    private func updateIdentityInformation() {
        isLoggedIn = SRGIdentityService.current?.isLoggedIn ?? false
        account = SRGIdentityService.current?.account
    }
    
    private func updateHistoryInformation() {
        SRGUserData.current?.history.historyEntries(matching: nil, sortedWith: nil) { historyEntries, _ in
            guard let isEmpty = historyEntries?.isEmpty else { return }
            DispatchQueue.main.async {
                self.hasHistoryEntries = !isEmpty
            }
        }
    }
    
    private func updateFavoritesInformation() {
        hasFavorites = !FavoritesShowURNs().isEmpty
    }
    
    private func updateWatchLaterInformation() {
        SRGUserData.current?.playlists.playlistEntriesInPlaylist(withUid: SRGPlaylistUid.watchLater.rawValue, matching: nil, sortedWith: nil) { entries, _ in
            guard let isEmpty = entries?.isEmpty else { return }
            DispatchQueue.main.async {
                self.hasWatchLaterItems = !isEmpty
            }
        }
    }
    
    private func updateSynchronizationDate() {
        synchronizationDate = SRGUserData.current?.user.synchronizationDate
    }
}
