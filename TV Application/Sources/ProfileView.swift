//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGIdentity
import SRGUserData
import SwiftUI

struct ProfileView: View {
    @State var isLoggedIn: Bool = false
    @State var account: SRGAccount?
    @State var hasHistoryEntries: Bool = false
    @State var hasFavorites: Bool = false
    
    @AppStorage(PlaySRGSettingAutoplayEnabled) var isAutoplayEnabled: Bool = false
    
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
    
    private var loginButtonText: String {
        guard isLoggedIn else { return  NSLocalizedString("Login", comment: "Login button on Apple TV") }
        
        if let username = account?.displayName ?? SRGIdentityService.current?.emailAddress {
            return String(format: NSLocalizedString("Logout (%@)", comment: "Logout button on Apple TV"), username)
        }
        else {
            return NSLocalizedString("Logout", comment: "Logout button on Apple TV")
        }
    }
    
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
    
    private func logoutAlert() -> Alert {
        let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of the cancel button in the alert view when logout"))) {}
        let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Logout", comment: "Logout button on Apple TV"))) {
            SRGIdentityService.current?.logout()
        }
        return Alert(title: Text(NSLocalizedString("Logout", comment: "Logout alert view title on Apple TV")),
                     message: Text(NSLocalizedString("Are you sure you want to logout?", comment: "Confirmation message displayed when the user is about to logout on Apple TV")),
                     primaryButton: primaryButton,
                     secondaryButton: secondaryButton)
    }
    
    private func historyRemovalAlert() -> Alert {
        let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
        let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
            SRGUserData.current?.history.discardHistoryEntries(withUids: nil, completionBlock: nil)
        }
        if let isLoggedIn = SRGIdentityService.current?.isLoggedIn, isLoggedIn {
            return Alert(title: Text(NSLocalizedString("Delete history", comment: "Title of the confirmation pop-up displayed when the user is about to clear the history")),
                         message: Text(NSLocalizedString("This will erase the history on all devices connected to your account?", comment: "Confirmation message displayed when a logged in user is about to delete the whole history")),
                         primaryButton: primaryButton,
                         secondaryButton: secondaryButton)
        }
        else {
            return Alert(title: Text(NSLocalizedString("Delete history", comment: "Title of the confirmation pop-up displayed when the user is about to clear the history")),
                         message: Text(NSLocalizedString("Are you sure you want to erase the whole history?", comment: "Confirmation message displayed when the user is about to delete the whole history")),
                         primaryButton: primaryButton,
                         secondaryButton: secondaryButton)
        }
    }
    
    private func favoritesRemovalAlert() -> Alert {
        let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
        let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
            FavoritesRemoveShows(nil);
        }
        if let isLoggedIn = SRGIdentityService.current?.isLoggedIn, isLoggedIn {
            return Alert(title: Text(NSLocalizedString("Remove all favorites", comment: "Title of the confirmation pop-up displayed when the user is about to delete all favorite items")),
                         message: Text(NSLocalizedString("This will remove all favorites and associated notification subscriptions on all devices connected to your account.", comment: "Confirmation message displayed when a logged in user is about to clean all favorites")),
                         primaryButton: primaryButton,
                         secondaryButton: secondaryButton)
        }
        else {
            return Alert(title: Text(NSLocalizedString("Remove all favorites", comment: "Title of the confirmation pop-up displayed when the user is about to delete all favorite items")),
                         message: Text(NSLocalizedString("Are you sure you want to remove all favorites?", comment: "Confirmation message displayed when the user is about to clean all favorites")),
                         primaryButton: primaryButton,
                         secondaryButton: secondaryButton)
        }
    }
    
    var body: some View {
        List {
            if let identityService = SRGIdentityService.current {
                Section(header: Text(NSLocalizedString("Profile", comment: "Settings section header")).srgFont(.headline1),
                        footer: Text(NSLocalizedString("Synchronize playback history, favorites and content to be watched later on all devices connected to your account", comment: "Login benefits description footer"))) {
                    Button(action: {
                        if isLoggedIn {
                            logoutAlertDisplayed = true
                        }
                        else {
                            identityService.login(withEmailAddress: nil)
                        }
                    }) {
                        Text(loginButtonText)
                            .srgFont(.button1)
                    }
                    .padding()
                    .alert(isPresented: $logoutAlertDisplayed, content: logoutAlert)
                }
            }
            Section(header: Text(NSLocalizedString("Playback", comment: "Playback settings section header")),
                    footer: Text(NSLocalizedString("When enabled, more content is automatically played after playback of the current content ends.", comment: "Playback description footer"))) {
                Button(action: {
                    isAutoplayEnabled = !isAutoplayEnabled
                }) {
                    HStack {
                        Text(NSLocalizedString("Autoplay", comment: "Autoplay setting"))
                            .srgFont(.button1)
                        Spacer()
                        Text(isAutoplayEnabled ? NSLocalizedString("Enabled", comment: "Enabled state label") : NSLocalizedString("Disabled", comment: "Disabled state label"))
                            .srgFont(.button1)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            Section(header: Text(NSLocalizedString("Content", comment: "Settings section header")).srgFont(.headline1),
                    footer: Text(Self.version).srgFont(.overline).opacity(0.8)) {
                Button(action: {
                    if hasHistoryEntries {
                        historyRemovalAlertDisplayed = true
                    }
                }) {
                    Text(NSLocalizedString("Delete history", comment: "Delete history button title"))
                        .srgFont(.button1)
                        .foregroundColor(hasHistoryEntries ? .primary : .gray)
                }
                .padding()
                .alert(isPresented: $historyRemovalAlertDisplayed, content: historyRemovalAlert)

                Button(action: {
                    if hasFavorites {
                        favoritesRemovalAlertDisplayed = true
                    }
                }) {
                    Text(NSLocalizedString("Remove all favorites", comment: "Remove all favorites button title"))
                        .srgFont(.button1)
                        .foregroundColor(hasFavorites ? .primary : .gray)
                }
                .padding()
                .alert(isPresented: $favoritesRemovalAlertDisplayed, content: favoritesRemovalAlert)
            }
        }
        .listStyle(GroupedListStyle())
        .frame(maxWidth: 1054)
        .padding(.top, 100)
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
