//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGIdentity
import SRGUserData
import SwiftUI

struct SettingsView: View {
    @State var isLoggedIn: Bool = false
    @State var account: SRGAccount?
    @State var hasHistoryEntries: Bool = false
    @State var hasFavorites: Bool = false
    
    @State var displayLogoutAlert = false
    @State var displayRemoveFavoritesAlert = false
    @State var displayRemoveHistoryAlert = false
    
    private static let version: String = {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let bundleNameSuffix = Bundle.main.infoDictionary!["BundleNameSuffix"] as! String
        let buildName = Bundle.main.infoDictionary!["BuildName"] as! String
        let buildString = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        return String(format: "%@%@%@ (%@)", appVersion, bundleNameSuffix.count > 0 ? " " + bundleNameSuffix : "", buildName.count > 0 ? " " + buildName : "", buildString)
    }()
    
    private func refreshIdentityInformation() {
        isLoggedIn = (SRGIdentityService.current != nil) ? SRGIdentityService.current!.isLoggedIn : false
        account = SRGIdentityService.current?.account
    }
    
    private func refresHistoryInformation() {
        hasHistoryEntries = SRGUserData.current?.history.historyEntries(matching: nil, sortedWith: nil).count ?? 0 > 0
    }
    
    private func refresFavoritesInformation() {
        hasFavorites = FavoritesShowURNs().count > 0
    }
    
    var body: some View {
        VStack() {
            Spacer()
            if let identityService: SRGIdentityService = SRGIdentityService.current {
                if isLoggedIn {
                    let emailAddress = identityService.emailAddress
                    let accountDisplayName = account?.displayName
                    Text(accountDisplayName != nil ? accountDisplayName! : emailAddress != nil  ? emailAddress! : NSLocalizedString("My account", comment: "Text displayed when a user is logged in but no information has been retrieved yet"))
                }
                else {
                    Text(NSLocalizedString("Not logged in", comment: "Text displayed when no user is logged in"))
                }
                Button(action: {
                    if (isLoggedIn) {
                        self.displayLogoutAlert = true
                    }
                    else {
                        identityService.login(withEmailAddress: nil)
                    }
                }) {
                    Text(isLoggedIn ? NSLocalizedString("Logout", comment: "Logout button on Apple TV") : NSLocalizedString("Login", comment: "Login button on Apple TV"))
                }
                .padding()
                .alert(isPresented: $displayLogoutAlert) {
                    let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of the cancel button in the alert view when logout"))) {}
                    let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Logout", comment: "Logout button on Apple TV"))) {
                        identityService.logout()
                    }
                    return Alert(title: Text(NSLocalizedString("Logout", comment: "Logout alert view title on Apple TV")),
                                 message: Text(NSLocalizedString("Are you sure you want to logout?", comment: "Confirmation message displayed when the user is about to logout on Apple TV")),
                                 primaryButton: primaryButton,
                                 secondaryButton: secondaryButton)
                }
            }
            if hasHistoryEntries {
                Button(action: {
                    self.displayRemoveHistoryAlert = true
                }) {
                    Text(NSLocalizedString("Delete history", comment: "Delete history button title"))
                }
                .padding()
                .alert(isPresented: $displayRemoveHistoryAlert) {
                    let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
                    let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                        SRGUserData.current?.history.discardHistoryEntries(withUids: nil, completionBlock: nil)
                    }
                    return Alert(title: Text(NSLocalizedString("Delete history", comment: "Title of the confirmation pop-up displayed when the user is about to clear the history")),
                                 message: Text(NSLocalizedString("Are you sure you want to delete all items?", comment: "Confirmation message displayed when the user is about to delete the whole history")),
                                 primaryButton: primaryButton,
                                 secondaryButton: secondaryButton)
                }
            }
            else {
                Text(NSLocalizedString("No history", comment: "Text displayed when no history is available"))
                    .padding()
            }
            if hasFavorites {
                Button(action: {
                    self.displayRemoveFavoritesAlert = true
                }) {
                    Text(NSLocalizedString("Remove all favorites", comment: "Remove all favorites button title"))
                }
                .padding()
                .alert(isPresented: $displayRemoveFavoritesAlert) {
                    let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
                    let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                        FavoritesRemoveShows(nil);
                    }
                    return Alert(title: Text(NSLocalizedString("Remove all favorites", comment: "Title of the confirmation pop-up displayed when the user is about to delete all favorite items")),
                                 message: Text(NSLocalizedString("Are you sure you want to delete all items?", comment: "Confirmation message displayed when the user is about to clean all favorites")),
                                 primaryButton: primaryButton,
                                 secondaryButton: secondaryButton)
                }
            }
            else {
                Text(NSLocalizedString("No favorites", comment: "Text displayed when no favorites are available"))
                    .padding()
            }
            Spacer()
            Text(Self.version)
        }
        .onAppear {
            refreshIdentityInformation()
            refresHistoryInformation()
            refresFavoritesInformation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceUserDidCancelLogin, object: SRGIdentityService.current)) { notification in
            refreshIdentityInformation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceUserDidLogin, object: SRGIdentityService.current)) { notification in
            refreshIdentityInformation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceDidUpdateAccount, object: SRGIdentityService.current)) { notification in
            refreshIdentityInformation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceUserDidLogout, object: SRGIdentityService.current)) { notification in
            refreshIdentityInformation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)) { notification in
            refresHistoryInformation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGPreferencesDidChange, object: SRGUserData.current?.preferences)) { notification in
            refresFavoritesInformation()
        }
    }
}
