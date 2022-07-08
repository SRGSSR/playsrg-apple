//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGIdentity
import SRGUserData
import YYWebImage

// MARK: View model

final class SettingsViewModel: ObservableObject {
    @Published private(set) var isLoggedIn = false
#if os(tvOS)
    @Published private(set) var account: SRGAccount?
#endif
    @Published private(set) var hasHistoryEntries = false
    @Published private(set) var hasFavorites = false
    @Published private(set) var hasWatchLaterItems = false
    @Published private var synchronizationDate: Date?
    
    init() {
        NotificationCenter.default.publisher(for: .SRGUserDataDidFinishSynchronization, object: SRGUserData.current)
            .map { _ in }
            .prepend(())
            .map { SRGUserData.current!.user.synchronizationDate }
            .assign(to: &$synchronizationDate)
        
        if let identityService = SRGIdentityService.current {
            Self.loggedInReloadSignal(for: identityService)
                .prepend(())
                .map { identityService.isLoggedIn }
                .assign(to: &$isLoggedIn)
            
#if os(tvOS)
            NotificationCenter.default.publisher(for: .SRGIdentityServiceDidUpdateAccount, object: identityService)
                .map { _ in }
                .prepend(())
                .map { identityService.account }
                .assign(to: &$account)
#endif
        }
        
        ThrottledSignal.historyUpdates()
            .prepend(())
            .map { [weak self] _ in
                return SRGDataProvider.current!.historyEntriesPublisher()
                    .map { !$0.isEmpty }
                    .replaceError(with: self?.hasHistoryEntries ?? false)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasHistoryEntries)
        
        ThrottledSignal.preferenceUpdates()
            .prepend(())
            .map { FavoritesShowURNs().count != 0 }
            .assign(to: &$hasFavorites)
        
        ThrottledSignal.watchLaterUpdates()
            .prepend(())
            .map { [weak self] _ in
                return SRGDataProvider.current!.laterEntriesPublisher()
                    .map { !$0.isEmpty }
                    .replaceError(with: self?.hasWatchLaterItems ?? false)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasWatchLaterItems)
    }
    
    private static func loggedInReloadSignal(for identityService: SRGIdentityService) -> AnyPublisher<Void, Never> {
        return Publishers.Merge3(
            NotificationCenter.default.publisher(for: .SRGIdentityServiceUserDidCancelLogin, object: identityService),
            NotificationCenter.default.publisher(for: .SRGIdentityServiceUserDidLogin, object: identityService),
            NotificationCenter.default.publisher(for: .SRGIdentityServiceUserDidLogout, object: identityService)
        )
        .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
        .map { _ in }
        .eraseToAnyPublisher()
    }
    
    private static func string(for date: Date?) -> String {
        if let date = date {
            return DateFormatter.play_relativeDateAndTime.string(from: date)
        }
        else {
            return NSLocalizedString("Never", comment: "Text displayed when no data synchronization has been made yet")
        }
    }
    
#if os(tvOS)
    var supportsLogin: Bool {
        return SRGIdentityService.current != nil
    }
    
    var username: String? {
        return account?.displayName ?? SRGIdentityService.current?.emailAddress
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
#endif
    
    var synchronizationStatus: String? {
        guard let identityService = SRGIdentityService.current, identityService.isLoggedIn else { return nil }
        return String(format: NSLocalizedString("Last synchronization: %@", comment: "Introductory text for the most recent data synchronization date"), Self.string(for: synchronizationDate))
    }
        
    var version: String {
        return Bundle.main.play_friendlyVersionNumber
    }
    
    var whatsNewURL: URL {
        return ApplicationConfiguration.shared.whatsNewURL
    }
    
#if os(iOS)
    func openSystemSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    var showImpressum: (() -> Void)? {
        guard let url = ApplicationConfiguration.shared.impressumURL else { return nil }
        return {
            UIApplication.shared.open(url)
        }
    }
    
    var showTermsAndConditions: (() -> Void)? {
        guard let url = ApplicationConfiguration.shared.termsAndConditionsURL else { return nil }
        return {
            UIApplication.shared.open(url)
        }
    }
    
    var showDataProtection: (() -> Void)? {
        guard let url = ApplicationConfiguration.shared.dataProtectionURL else { return nil }
        return {
            UIApplication.shared.open(url)
        }
    }
    
    var showSourceCode: (() -> Void)? {
        guard let url = ApplicationConfiguration.shared.sourceCodeURL else { return nil }
        return {
            UIApplication.shared.open(url)
        }
    }
    
    var becomeBetaTester: (() -> Void)? {
        guard let url = ApplicationConfiguration.shared.betaTestingURL else { return nil }
        return {
            UIApplication.shared.open(url)
        }
    }
    
    var openFeedbackForm: (() -> Void)? {
        guard let url = ApplicationConfiguration.shared.feedbackUrlWithParameters else { return nil }
        return {
            UIApplication.shared.open(url)
        }
    }
    
    func copySupportInformation() {
        UIPasteboard.general.string = SupportInformation.generate()
    }
#endif
    
    func removeHistory() {
        SRGUserData.current?.history.discardHistoryEntries(withUids: nil, completionBlock: nil)
    }
    
    func removeFavorites() {
        FavoritesRemoveShows(nil)
    }
    
    func removeWatchLaterItems() {
        SRGUserData.current?.playlists.discardPlaylistEntries(withUids: nil, fromPlaylistWithUid: SRGPlaylistUid.watchLater.rawValue, completionBlock: nil)
    }
    
    func clearWebCache() {
        URLCache.shared.removeAllCachedResponses()
        
        if let cache = YYWebImageManager.shared().cache {
            cache.memoryCache.removeAllObjects()
            cache.diskCache.removeAllObjects()
        }
    }
    
    func clearVectorImageCache() {
        UIImage.srg_clearVectorImageCache()
    }
    
    func clearAllContents() {
        clearWebCache()
        clearVectorImageCache()
#if os(iOS)
        Download.removeAllDownloads()
#endif
    }
    
#if DEBUG || NIGHTLY || BETA
    func simulateMemoryWarning() {
        let selector = Selector("_p39e45r2f435o6r7837m12M34e5m6o67r8y8W9a9r66654n43i3n2g".unobfuscated())
        UIApplication.shared.perform(selector)
    }
#endif
}