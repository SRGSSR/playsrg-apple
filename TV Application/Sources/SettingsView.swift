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
    
    @State var logoutAlertDisplayed = false
    @State var favoritesRemovalAlertDisplayed = false
    @State var historyRemovalAlertDisplayed = false
    
    private static let version: String = {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let bundleNameSuffix = Bundle.main.infoDictionary!["BundleNameSuffix"] as! String
        let buildName = Bundle.main.infoDictionary!["BuildName"] as! String
        let buildString = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        return String(format: "%@%@%@ (%@)", appVersion, bundleNameSuffix.count > 0 ? " " + bundleNameSuffix : "", buildName.count > 0 ? " " + buildName : "", buildString)
    }()
    
    private func refreshIdentityInformation() {
        isLoggedIn = SRGIdentityService.current?.isLoggedIn ?? false
        account = SRGIdentityService.current?.account
    }
    
    private func refreshHistoryInformation() {
        let historyEntriesCount = SRGUserData.current?.history.historyEntries(matching: nil, sortedWith: nil).count ?? 0
        hasHistoryEntries = historyEntriesCount > 0
    }
    
    private func refreshFavoritesInformation() {
        hasFavorites = FavoritesShowURNs().count > 0
    }
    
    var body: some View {
        HStack(spacing: 100) {
            VStack(spacing: 50) {
                Spacer()
                Image(uiImage: UIImage(named: "App Icon")!)
                    .cornerRadius(25)
                Text(Self.version)
                    .srgFont(.overline)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            List {
                if let identityService = SRGIdentityService.current {
                    Section(header: Text(NSLocalizedString("Profile", comment: "Settings section header")).srgFont(.headline1)) {
                    if isLoggedIn {
                        Text(account?.displayName ?? identityService.emailAddress ?? NSLocalizedString("My account", comment: "Text displayed when a user is logged in but no information has been retrieved yet"))
                            .srgFont(.subtitle)
                            .padding()
                    }
                    else {
                        Text(NSLocalizedString("Not logged in", comment: "Text displayed when no user is logged in"))
                            .srgFont(.subtitle)
                            .padding()
                    }
                    Button(action: {
                        if isLoggedIn {
                            self.logoutAlertDisplayed = true
                        }
                        else {
                            identityService.login(withEmailAddress: nil)
                        }
                    }) {
                        Text(isLoggedIn ? NSLocalizedString("Logout", comment: "Logout button on Apple TV") : NSLocalizedString("Login", comment: "Login button on Apple TV"))
                            .srgFont(.subtitle)
                    }
                    .padding()
                    .alert(isPresented: $logoutAlertDisplayed) {
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
                }
                Section(header: Text(NSLocalizedString("Content", comment: "Settings section header")).srgFont(.headline1)) {
                if hasHistoryEntries {
                    Button(action: {
                        self.historyRemovalAlertDisplayed = true
                    }) {
                        Text(NSLocalizedString("Delete history", comment: "Delete history button title"))
                            .srgFont(.subtitle)
                    }
                    .padding()
                    .alert(isPresented: $historyRemovalAlertDisplayed) {
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
                        .srgFont(.subtitle)
                        .padding()
                }
                if hasFavorites {
                    Button(action: {
                        self.favoritesRemovalAlertDisplayed = true
                    }) {
                        Text(NSLocalizedString("Remove all favorites", comment: "Remove all favorites button title"))
                            .srgFont(.subtitle)
                    }
                    .padding()
                    .alert(isPresented: $favoritesRemovalAlertDisplayed) {
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
                        .srgFont(.subtitle)
                        .padding()
                }
                }
            }
            .listStyle(GroupedListStyle())
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            refreshIdentityInformation()
            refreshHistoryInformation()
            refreshFavoritesInformation()
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
            refreshHistoryInformation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGPreferencesDidChange, object: SRGUserData.current?.preferences)) { notification in
            refreshFavoritesInformation()
        }
    }
}
