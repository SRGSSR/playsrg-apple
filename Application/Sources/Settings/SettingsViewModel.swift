//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGIdentity
import SRGUserData

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
    
    func openSystemSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    func showSourceCode() {
        guard let url = ApplicationConfiguration.shared.sourceCodeURL else { return }
        UIApplication.shared.open(url)
    }
    
    func becomeBetaTester() {
        guard let url = ApplicationConfiguration.shared.betaTestingURL else { return }
        UIApplication.shared.open(url)
    }
    
    func deleteHistory() {
        
    }
    
    func deleteFavorites() {
        
    }
    
    func deleteWatchLater() {
        
    }
}
