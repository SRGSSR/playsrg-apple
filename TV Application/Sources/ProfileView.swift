//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGUserData
import SwiftUI

struct ProfileView: View {
    @StateObject var model = ProfileModel()
    
    var synchronizationMessage: String? {
        guard model.isLoggedIn else { return nil }
        let dateString = (model.synchronizationDate != nil) ? DateFormatter.play_relativeDateAndTime.string(from: model.synchronizationDate!) : NSLocalizedString("Never", comment: "Text displayed when no data synchronization has been made yet")
        return String(format: NSLocalizedString("Last synchronization: %@", comment: "Introductory text for the most recent data synchronization date"), dateString)
    }
    
    var body: some View {
        List {
            if model.supportsLogin {
                Section(header: Text(NSLocalizedString("Profile", comment: "Settings section header")).srgFont(.headline1),
                        footer: Text(NSLocalizedString("Synchronize playback history, favorites and content to be watched later on all devices connected to your account.", comment: "Login benefits description footer")).srgFont(.overline).opacity(0.8)) {
                    ProfileListItem(model: model)
                }
            }
            Section(header: Text(NSLocalizedString("Playback", comment: "Playback settings section header")),
                    footer: Text(NSLocalizedString("When enabled, more content is automatically played after playback of the current content ends.", comment: "Playback description footer")).srgFont(.overline).opacity(0.8)) {
                AutoplayListItem()
            }
            if let synchronizationMessage = synchronizationMessage {
                Section(header: Text(NSLocalizedString("Content", comment: "Settings section header")).srgFont(.headline1),
                        footer: Text(synchronizationMessage).srgFont(.overline).opacity(0.8)) {
                    HistoryRemovalListItem(model: model)
                    FavoritesRemovalListItem(model: model)
                }
            }
            else {
                Section(header: Text(NSLocalizedString("Content", comment: "Settings section header")).srgFont(.headline1)) {
                    HistoryRemovalListItem(model: model)
                    FavoritesRemovalListItem(model: model)
                }
            }
            Section(header: Text(NSLocalizedString("Information", comment: "Information section header")).srgFont(.headline1)) {
                VersionListItem(model: model)
            }
        }
        .listStyle(GroupedListStyle())
        .frame(maxWidth: 1054)
        .padding(.top, model.supportsLogin ? 0 : 100)
    }
    
    struct ProfileListItem: View {
        @ObservedObject var model: ProfileModel
        @State var alertDisplayed = false
        
        var text: String {
            guard model.isLoggedIn else { return  NSLocalizedString("Login", comment: "Login button on Apple TV") }
            if let username = model.username {
                return NSLocalizedString("Logout", comment: "Logout button on Apple TV").appending(" (\(username))")
            }
            else {
                return NSLocalizedString("Logout", comment: "Logout button on Apple TV")
            }
        }
        
        func alert() -> Alert {
            let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of the cancel button in the alert view when logout"))) {}
            let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Logout", comment: "Logout button on Apple TV"))) {
                model.logout()
            }
            return Alert(title: Text(NSLocalizedString("Logout", comment: "Logout alert view title on Apple TV")),
                         message: Text(NSLocalizedString("Are you sure you want to logout?", comment: "Confirmation message displayed when the user is about to logout on Apple TV")),
                         primaryButton: primaryButton,
                         secondaryButton: secondaryButton)
        }
        
        var body: some View {
            Button(action: {
                if model.isLoggedIn {
                    alertDisplayed = true
                }
                else {
                    model.login()
                }
            }) {
                Text(text)
                    .srgFont(.button1)
            }
            .padding()
            .alert(isPresented: $alertDisplayed, content: alert)
        }
    }
    
    struct AutoplayListItem: View {
        @AppStorage(PlaySRGSettingAutoplayEnabled) var isAutoplayEnabled: Bool = false
        
        var body: some View {
            Button(action: {
                isAutoplayEnabled = !isAutoplayEnabled
            }) {
                HStack {
                    Text(NSLocalizedString("Autoplay", comment: "Autoplay setting"))
                        .srgFont(.button1)
                    Spacer()
                    Text(isAutoplayEnabled ? NSLocalizedString("Enabled", comment: "Enabled state label") : NSLocalizedString("Disabled", comment: "Disabled state label"))
                        .srgFont(.button1)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    struct HistoryRemovalListItem: View {
        @ObservedObject var model: ProfileModel
        @State var alertDisplayed = false
        
        func alert() -> Alert {
            let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
            let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                model.removeHistory()
            }
            if model.isLoggedIn {
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
        
        var body: some View {
            Button(action: {
                if model.hasHistoryEntries {
                    alertDisplayed = true
                }
            }) {
                Text(NSLocalizedString("Delete history", comment: "Delete history button title"))
                    .srgFont(.button1)
                    .foregroundColor(model.hasHistoryEntries ? .primary : .secondary)
            }
            .padding()
            .alert(isPresented: $alertDisplayed, content: alert)
        }
    }
    
    struct FavoritesRemovalListItem: View {
        @ObservedObject var model: ProfileModel
        @State var alertDisplayed = false
        
        func alert() -> Alert {
            let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
            let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                model.removeFavorites()
            }
            if model.isLoggedIn {
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
            Button(action: {
                if model.hasFavorites {
                    alertDisplayed = true
                }
            }) {
                Text(NSLocalizedString("Remove all favorites", comment: "Remove all favorites button title"))
                    .srgFont(.button1)
                    .foregroundColor(model.hasFavorites ? .primary : .secondary)
            }
            .padding()
            .alert(isPresented: $alertDisplayed, content: alert)
        }
    }
    
    struct VersionListItem: View {
        var model: ProfileModel
        
        var body: some View {
            Button(action: {}) {
                HStack {
                    Text(NSLocalizedString("Version", comment: "Version introductory label"))
                        .srgFont(.button1)
                    Spacer()
                    Text(model.version)
                        .srgFont(.button1)
                }
                .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}
