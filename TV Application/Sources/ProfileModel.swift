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
    @Published private(set) var account: SRGAccount? = nil
    @Published private(set) var hasHistoryEntries = false
    @Published private(set) var hasFavorites = false
    @Published private(set) var synchronizationDate: Date? = nil
    
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
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGPreferencesDidChange, object: SRGUserData.current?.preferences)
            .sink { _ in
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
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let bundleNameSuffix = Bundle.main.infoDictionary!["BundleNameSuffix"] as! String
        let buildName = Bundle.main.infoDictionary!["BuildName"] as! String
        let buildString = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
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
        FavoritesRemoveShows(nil);
    }
    
    private func updateIdentityInformation() {
        isLoggedIn = SRGIdentityService.current?.isLoggedIn ?? false
        account = SRGIdentityService.current?.account
    }
    
    private func updateHistoryInformation() {
        let historyEntriesCount = SRGUserData.current?.history.historyEntries(matching: nil, sortedWith: nil).count ?? 0
        hasHistoryEntries = historyEntriesCount > 0
    }
    
    private func updateFavoritesInformation() {
        hasFavorites = FavoritesShowURNs().count > 0
    }
    
    private func updateSynchronizationDate() {
        synchronizationDate = SRGUserData.current?.user.synchronizationDate
    }
}
