//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGUserData
import SwiftUI

struct ProfileView: View {
    @StateObject private var model = ProfileModel()
    
    private var synchronizationMessage: String? {
        guard model.isLoggedIn else { return nil }
        let dateString = (model.synchronizationDate != nil) ? DateFormatter.play_relativeDateAndTime.string(from: model.synchronizationDate!) : NSLocalizedString("Never", comment: "Text displayed when no data synchronization has been made yet")
        return String(format: NSLocalizedString("Last synchronization: %@", comment: "Introductory text for the most recent data synchronization date"), dateString)
    }
    
    var body: some View {
        List {
            if model.supportsLogin {
                SwiftUI.Section(header: Text(NSLocalizedString("Profile", comment: "Profile section header")).srgFont(.H3),
                        footer: Text(NSLocalizedString("Synchronize playback history, favorites and content saved for later on all devices connected to your account.", comment: "Login benefits description footer")).srgFont(.subtitle2).opacity(0.8)) {
                    ProfileListItem(model: model)
                }
            }
            if let synchronizationMessage = synchronizationMessage {
                SwiftUI.Section(header: Text(NSLocalizedString("Content", comment: "Profile content section header")).srgFont(.H3),
                        footer: Text(synchronizationMessage).srgFont(.subtitle2).opacity(0.8)) {
                    HistoryRemovalListItem(model: model)
                    FavoritesRemovalListItem(model: model)
                    WatchLaterRemovalListItem(model: model)
                }
            }
            else {
                SwiftUI.Section(header: Text(NSLocalizedString("Content", comment: "Profile content section header")).srgFont(.H3)) {
                    HistoryRemovalListItem(model: model)
                    FavoritesRemovalListItem(model: model)
                    WatchLaterRemovalListItem(model: model)
                }
            }
            if ApplicationConfiguration.shared.isContinuousPlaybackAvailable {
                SwiftUI.Section(header: Text(PlaySRGSettingsLocalizedString("Playback", "Playback settings section header")),
                        footer: Text(PlaySRGSettingsLocalizedString("When enabled, more content is automatically played after playback of the current content ends.", "Playback description footer")).srgFont(.subtitle2).opacity(0.8)) {
                    AutoplayListItem()
                }
            }
            if !ApplicationConfiguration.shared.isSubtitleAvailabilityHidden || !ApplicationConfiguration.shared.isAudioDescriptionAvailabilityHidden {
                SwiftUI.Section(header: Text(PlaySRGSettingsLocalizedString("Display", "Display settings section header")),
                        footer: Text(PlaySRGSettingsLocalizedString("Always visible when VoiceOver is active.", "Display description footer")).srgFont(.subtitle2).opacity(0.8)) {
                    if !ApplicationConfiguration.shared.isSubtitleAvailabilityHidden {
                        SubtitleAvailabilityListItem()
                    }
                    if !ApplicationConfiguration.shared.isAudioDescriptionAvailabilityHidden {
                        AudioDescriptionAvailabilityListItem()
                    }
                }
            }
            #if DEBUG || NIGHTLY || BETA
            SwiftUI.Section(header: Text(PlaySRGSettingsLocalizedString("Advanced features", "Advanced features section header")).srgFont(.H3),
                            footer: Text(PlaySRGSettingsLocalizedString("This section is only available in nightly and beta versions, and won't appear in the production version.", "Advanced features section footer")).srgFont(.subtitle2).opacity(0.8)) {
                SectionWideSupportItem()
            }
            #endif
            SwiftUI.Section(header: Text(PlaySRGSettingsLocalizedString("Information", "Information section header")).srgFont(.H3)) {
                VersionListItem(model: model)
            }
        }
        .listStyle(GroupedListStyle())
        .frame(maxWidth: 1054)
        .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
    }
    
    struct ProfileListItem: View {
        @ObservedObject var model: ProfileModel
        @State var alertDisplayed = false
        
        private var text: String {
            guard model.isLoggedIn else { return NSLocalizedString("Login", comment: "Login button on Apple TV") }
            if let username = model.username {
                return NSLocalizedString("Logout", comment: "Logout button on Apple TV").appending(" (\(username))")
            }
            else {
                return NSLocalizedString("Logout", comment: "Logout button on Apple TV")
            }
        }
        
        private func alert() -> Alert {
            let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of the cancel button in the alert view when logout"))) {}
            let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Logout", comment: "Logout button on Apple TV"))) {
                model.logout()
            }
            return Alert(title: Text(NSLocalizedString("Logout", comment: "Logout alert view title on Apple TV")),
                         message: Text(NSLocalizedString("Playback history, favorites and content saved for later will be deleted from this Apple TV.", comment: "Message displayed when the user is about to log out")),
                         primaryButton: primaryButton,
                         secondaryButton: secondaryButton)
        }
        
        private func action() {
            if model.isLoggedIn {
                alertDisplayed = true
            }
            else {
                model.login()
            }
        }
        
        var body: some View {
            Button(action: action) {
                Text(text)
                    .srgFont(.button)
            }
            .padding()
            .alert(isPresented: $alertDisplayed, content: alert)
        }
    }
    
    struct AutoplayListItem: View {
        @AppStorage(PlaySRGSettingAutoplayEnabled) var isAutoplayEnabled = false
        
        private func action() {
            isAutoplayEnabled = !isAutoplayEnabled
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Autoplay", "Autoplay setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(isAutoplayEnabled ? PlaySRGSettingsLocalizedString("On", "Enabled state label on Apple TV") : PlaySRGSettingsLocalizedString("Off", "Disabled state label on Apple TV"))
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    struct SubtitleAvailabilityListItem: View {
        @AppStorage(PlaySRGSettingSubtitleAvailabilityDisplayed) var isSubtitleAvailabilityDisplayed = false
        
        private func action() {
            isSubtitleAvailabilityDisplayed = !isSubtitleAvailabilityDisplayed
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Subtitle availability", "Subtitle availability setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(isSubtitleAvailabilityDisplayed ? PlaySRGSettingsLocalizedString("On", "Enabled state label on Apple TV") : PlaySRGSettingsLocalizedString("Off", "Disabled state label on Apple TV"))
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    struct AudioDescriptionAvailabilityListItem: View {
        @AppStorage(PlaySRGSettingAudioDescriptionAvailabilityDisplayed) var isAudioDescriptionAvailabilityDisplayed = false
        
        private func action() {
            isAudioDescriptionAvailabilityDisplayed = !isAudioDescriptionAvailabilityDisplayed
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Audio description availability", "Audio description availability setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(isAudioDescriptionAvailabilityDisplayed ? PlaySRGSettingsLocalizedString("On", "Enabled state label on Apple TV") : PlaySRGSettingsLocalizedString("Off", "Disabled state label on Apple TV"))
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    struct HistoryRemovalListItem: View {
        @ObservedObject var model: ProfileModel
        @State var alertDisplayed = false
        
        private func alert() -> Alert {
            let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
            let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                model.removeHistory()
            }
            if model.isLoggedIn {
                return Alert(title: Text(NSLocalizedString("Delete history", comment: "Title of the message displayed when the user is about to delete the history")),
                             message: Text(NSLocalizedString("The history will be deleted on all devices connected to your account.", comment: "Message displayed when the user is about to delete the history")),
                             primaryButton: primaryButton,
                             secondaryButton: secondaryButton)
            }
            else {
                return Alert(title: Text(NSLocalizedString("Delete history", comment: "Title of the message displayed when the user is about to delete the history")),
                             primaryButton: primaryButton,
                             secondaryButton: secondaryButton)
            }
        }
        
        private func action() {
            if model.hasHistoryEntries {
                alertDisplayed = true
            }
        }
        
        var body: some View {
            Button(action: action) {
                Text(NSLocalizedString("Delete history", comment: "Delete history button title"))
                    .srgFont(.button)
                    .foregroundColor(model.hasHistoryEntries ? .primary : .secondary)
            }
            .padding()
            .alert(isPresented: $alertDisplayed, content: alert)
        }
    }
    
    struct FavoritesRemovalListItem: View {
        @ObservedObject var model: ProfileModel
        @State var alertDisplayed = false
        
        private func alert() -> Alert {
            let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
            let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                model.removeFavorites()
            }
            if model.isLoggedIn {
                return Alert(title: Text(NSLocalizedString("Delete favorites", comment: "Title of the message displayed when the user is about to delete all favorites")),
                             message: Text(NSLocalizedString("Favorites and notification subscriptions will be deleted on all devices connected to your account.", comment: "Message displayed when the user is about to delete all favorites")),
                             primaryButton: primaryButton,
                             secondaryButton: secondaryButton)
            }
            else {
                return Alert(title: Text(NSLocalizedString("Delete favorites", comment: "Title of the message displayed when the user is about to delete all favorites")),
                             primaryButton: primaryButton,
                             secondaryButton: secondaryButton)
            }
        }
        
        private func action() {
            if model.hasFavorites {
                alertDisplayed = true
            }
        }
        
        var body: some View {
            Button(action: action) {
                Text(NSLocalizedString("Delete favorites", comment: "Delete favorites button title"))
                    .srgFont(.button)
                    .foregroundColor(model.hasFavorites ? .primary : .secondary)
            }
            .padding()
            .alert(isPresented: $alertDisplayed, content: alert)
        }
    }
    
    struct WatchLaterRemovalListItem: View {
        @ObservedObject var model: ProfileModel
        @State var alertDisplayed = false
        
        private func alert() -> Alert {
            let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
            let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                model.removeWatchLaterItems()
            }
            if model.isLoggedIn {
                return Alert(title: Text(NSLocalizedString("Delete content saved for later", comment: "Title of the message displayed when the user is about to delete content saved for later")),
                             message: Text(NSLocalizedString("Content saved for later will be deleted on all devices connected to your account.", comment: "Message displayed when the user is about to delete content saved for later")),
                             primaryButton: primaryButton,
                             secondaryButton: secondaryButton)
            }
            else {
                return Alert(title: Text(NSLocalizedString("Delete content saved for later", comment: "Title of the message displayed when the user is about to delete content saved for later")),
                             primaryButton: primaryButton,
                             secondaryButton: secondaryButton)
            }
        }
        
        private func action() {
            if model.hasWatchLaterItems {
                alertDisplayed = true
            }
        }
        
        var body: some View {
            Button(action: action) {
                Text(NSLocalizedString("Delete content saved for later", comment: "Title of the button to delete content saved for later"))
                    .srgFont(.button)
                    .foregroundColor(model.hasWatchLaterItems ? .primary : .secondary)
            }
            .padding()
            .alert(isPresented: $alertDisplayed, content: alert)
        }
    }
    
    #if DEBUG || NIGHTLY || BETA
    struct SectionWideSupportItem: View {
        @AppStorage(PlaySRGSettingSectionWideSupportEnabled) var isSectionWideSupportEnabled = false
        
        private func action() {
            isSectionWideSupportEnabled = !isSectionWideSupportEnabled
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Section wide support", "Section wide support setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(isSectionWideSupportEnabled ? PlaySRGSettingsLocalizedString("On", "Enabled state label on Apple TV") : PlaySRGSettingsLocalizedString("Off", "Disabled state label on Apple TV"))
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    #endif
    
    struct VersionListItem: View {
        var model: ProfileModel
        
        var body: some View {
            Button {
                // No action
            } label: {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Version", "Version introductory label"))
                        .srgFont(.button)
                    Spacer()
                    Text(model.version)
                        .srgFont(.button)
                }
                .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

extension ProfileView {
    private var analyticsPageTitle: String {
        return AnalyticsPageTitle.home.rawValue
    }
    
    private var analyticsPageLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.user.rawValue]
    }
}
