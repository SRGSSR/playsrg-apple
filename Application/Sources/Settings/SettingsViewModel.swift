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
    @Published private var synchronizationDate: Date?
    
    init() {
        NotificationCenter.default.publisher(for: .SRGUserDataDidFinishSynchronization, object: SRGUserData.current)
            .map { _ in }
            .prepend(())
            .map { SRGUserData.current?.user.synchronizationDate }
            .assign(to: &$synchronizationDate)
    }
    
    private static func string(for date: Date?) -> String {
        if let date = date {
            return DateFormatter.play_relativeDateAndTime.string(from: date)
        }
        else {
            return NSLocalizedString("Never", comment: "Text displayed when no data synchronization has been made yet")
        }
    }
    
    var synchronizationStatus: String? {
        guard let identityService = SRGIdentityService.current, identityService.isLoggedIn else { return nil }
        return String(format: NSLocalizedString("Last synchronization: %@", comment: "Introductory text for the most recent data synchronization date"), Self.string(for: synchronizationDate))
    }
    
    var version: String {
        return Bundle.main.play_friendlyVersionNumber
    }
    
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
    
    func copySupportInformation() {
        // TODO: Improvements pending, see PLAYRTS-4185
    }
    
    func deleteHistory() {
        // TODO:
    }
    
    func deleteFavorites() {
        // TODO:
    }
    
    func deleteWatchLater() {
        // TODO:
    }
    
    func subscribeToAllShows() {
        // TODO:
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
        Download.removeAllDownloads()
    }
    
    func simulateMemoryWarning() {
        // TODO:
    }
}
