//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAnalytics
import SRGUserData

// MARK: View model

final class ProfileViewModel: ObservableObject {
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
    
    private(set) var serviceURLTitle = PlaySRGSettingsLocalizedString("Production", comment: "Service URL setting state") {
        willSet {
            if serviceURLTitle != newValue {
                objectWillChange.send()
            }
        }
    }
    
    @Published private(set) var synchronizationDate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: .SRGIdentityServiceUserDidCancelLogin, object: SRGIdentityService.current)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIdentityInformation()
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .SRGIdentityServiceUserDidLogin, object: SRGIdentityService.current)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIdentityInformation()
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .SRGIdentityServiceDidUpdateAccount, object: SRGIdentityService.current)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIdentityInformation()
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .SRGIdentityServiceUserDidLogout, object: SRGIdentityService.current)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIdentityInformation()
            }
            .store(in: &cancellables)
        updateIdentityInformation()
        
        NotificationCenter.default.publisher(for: .SRGUserDataDidFinishSynchronization, object: SRGUserData.current)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSynchronizationDate()
            }
            .store(in: &cancellables)
        updateSynchronizationDate()
        
        ThrottledSignal.historyUpdates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateHistoryInformation()
            }
            .store(in: &cancellables)
        updateHistoryInformation()
        
        ThrottledSignal.watchLaterUpdates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateWatchLaterInformation()
            }
            .store(in: &cancellables)
        updateWatchLaterInformation()
        
        ThrottledSignal.preferenceUpdates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFavoritesInformation()
            }
            .store(in: &cancellables)
        updateFavoritesInformation()
        
        ApplicationSignal.settingUpdates(at: \.PlaySRGSettingServiceURL)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateServiceURLTitle()
            }
            .store(in: &cancellables)
        updateServiceURLTitle()
    }
    
    var supportsLogin: Bool {
        return SRGIdentityService.current != nil
    }
    
    var username: String? {
        return account?.displayName ?? SRGIdentityService.current?.emailAddress
    }
    
    var version: String {
        return Bundle.main.play_friendlyVersionNumber
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
    
    func nextServiceURL() {
        let serviceURL = ApplicationSettingServiceURL()
        if let index = Server.servers.firstIndex(where: { $0.url == serviceURL }) {
            let server = Server.servers[safeIndex: Server.servers.index(after: index)] ?? Server.servers.first!
            ApplicationSettingSetServiceURL(server.url)
            updateServiceURLTitle()
        }
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
        hasFavorites = (FavoritesShowURNs().count != 0)
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
    
    private func updateServiceURLTitle() {
        let serviceURL = ApplicationSettingServiceURL()
        let server = Server.servers.filter({ $0.url == serviceURL }).first ?? Server.servers.first!
        serviceURLTitle = server.title
    }
}
