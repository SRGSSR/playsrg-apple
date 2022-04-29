//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGUserData
import SwiftUI

struct ProfileView: View {
    @StateObject private var model = ProfileViewModel()
    
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
            if ApplicationConfiguration.shared.isContinuousPlaybackAvailable {
                SwiftUI.Section(header: Text(PlaySRGSettingsLocalizedString("Playback", comment: "Playback settings section header")).srgFont(.H3),
                        footer: Text(PlaySRGSettingsLocalizedString("When enabled, more content is automatically played after playback of the current content ends.", comment: "Playback description footer")).srgFont(.subtitle2).opacity(0.8)) {
                    AutoplayListItem()
                }
            }
            if !ApplicationConfiguration.shared.isSubtitleAvailabilityHidden || !ApplicationConfiguration.shared.isAudioDescriptionAvailabilityHidden {
                SwiftUI.Section(header: Text(PlaySRGSettingsLocalizedString("Display", comment: "Display settings section header")).srgFont(.H3),
                        footer: Text(PlaySRGSettingsLocalizedString("Always visible when VoiceOver is active.", comment: "Display description footer")).srgFont(.subtitle2).opacity(0.8)) {
                    if !ApplicationConfiguration.shared.isSubtitleAvailabilityHidden {
                        SubtitleAvailabilityListItem()
                    }
                    if !ApplicationConfiguration.shared.isAudioDescriptionAvailabilityHidden {
                        AudioDescriptionAvailabilityListItem()
                    }
                }
            }
            if let synchronizationMessage = synchronizationMessage {
                SwiftUI.Section(header: Text(PlaySRGSettingsLocalizedString("Content", comment: "Profile content section header")).srgFont(.H3),
                                footer: Text(synchronizationMessage).srgFont(.subtitle2).opacity(0.8)) {
                    HistoryRemovalListItem(model: model)
                    FavoritesRemovalListItem(model: model)
                    WatchLaterRemovalListItem(model: model)
                }
            }
            else {
                SwiftUI.Section(header: Text(PlaySRGSettingsLocalizedString("Content", comment: "Profile content section header")).srgFont(.H3)) {
                    HistoryRemovalListItem(model: model)
                    FavoritesRemovalListItem(model: model)
                    WatchLaterRemovalListItem(model: model)
                }
            }
            SwiftUI.Section(header: Text(PlaySRGSettingsLocalizedString("Information", comment: "Information section header")).srgFont(.H3)) {
                VersionListItem(model: model)
                SupportInformationListItem()
            }
            #if DEBUG || NIGHTLY || BETA
            SwiftUI.Section(header: Text(PlaySRGSettingsLocalizedString("Advanced features", comment: "Advanced features section header")).srgFont(.H3),
                            footer: Text(PlaySRGSettingsLocalizedString("This section is only available in nightly and beta versions, and won't appear in the production version.", comment: "Advanced features section footer")).srgFont(.subtitle2).opacity(0.8)) {
                ServiceURLItem(model: model)
                UserLocationItem()
                SectionWideSupportItem()
                PosterImagesItem()
            }
            #endif
        }
        .listStyle(GroupedListStyle())
        .frame(maxWidth: 1054)
        .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
    }
}

// MARK: List items

extension ProfileView {
    private struct ProfileListItem: View {
        @ObservedObject var model: ProfileViewModel
        @State private var alertDisplayed = false
        
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
    
    private struct AutoplayListItem: View {
        @AppStorage(PlaySRGSettingAutoplayEnabled) private var isAutoplayEnabled = false
        
        private func action() {
            isAutoplayEnabled.toggle()
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Autoplay", comment: "Autoplay setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(isAutoplayEnabled ? PlaySRGSettingsLocalizedString("On", comment: "Enabled state label on Apple TV") : PlaySRGSettingsLocalizedString("Off", comment: "Disabled state label on Apple TV"))
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    private struct SubtitleAvailabilityListItem: View {
        @AppStorage(PlaySRGSettingSubtitleAvailabilityDisplayed) private var isSubtitleAvailabilityDisplayed = false
        
        private func action() {
            isSubtitleAvailabilityDisplayed.toggle()
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Subtitle availability", comment: "Subtitle availability setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(isSubtitleAvailabilityDisplayed ? PlaySRGSettingsLocalizedString("On", comment: "Enabled state label on Apple TV") : PlaySRGSettingsLocalizedString("Off", comment: "Disabled state label on Apple TV"))
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    private struct AudioDescriptionAvailabilityListItem: View {
        @AppStorage(PlaySRGSettingAudioDescriptionAvailabilityDisplayed) private var isAudioDescriptionAvailabilityDisplayed = false
        
        private func action() {
            isAudioDescriptionAvailabilityDisplayed.toggle()
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Audio description availability", comment: "Audio description availability setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(isAudioDescriptionAvailabilityDisplayed ? PlaySRGSettingsLocalizedString("On", comment: "Enabled state label on Apple TV") : PlaySRGSettingsLocalizedString("Off", comment: "Disabled state label on Apple TV"))
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    private struct HistoryRemovalListItem: View {
        @ObservedObject var model: ProfileViewModel
        @State private var alertDisplayed = false
        
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
                Text(PlaySRGSettingsLocalizedString("Delete history", comment: "Delete history button title"))
                    .srgFont(.button)
                    .foregroundColor(model.hasHistoryEntries ? .primary : .secondary)
            }
            .padding()
            .alert(isPresented: $alertDisplayed, content: alert)
        }
    }
    
    private struct FavoritesRemovalListItem: View {
        @ObservedObject var model: ProfileViewModel
        @State private var alertDisplayed = false
        
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
                Text(PlaySRGSettingsLocalizedString("Delete favorites", comment: "Delete favorites button title"))
                    .srgFont(.button)
                    .foregroundColor(model.hasFavorites ? .primary : .secondary)
            }
            .padding()
            .alert(isPresented: $alertDisplayed, content: alert)
        }
    }
    
    private struct WatchLaterRemovalListItem: View {
        @ObservedObject var model: ProfileViewModel
        @State private var alertDisplayed = false
        
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
                return Alert(title: Text(PlaySRGSettingsLocalizedString("Delete content saved for later", comment: "Title of the message displayed when the user is about to delete content saved for later")),
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
    private struct ServiceURLItem: View {
        @ObservedObject var model: ProfileViewModel
        
        private func action() {
            model.nextServiceURL()
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Server", comment: "Service URL setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(model.serviceURLTitle)
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    private struct UserLocationItem: View {
        private enum SettingUserLocation: String {
            case `default` = ""
            case WW
            case CH
        }
        
        @AppStorage(PlaySRGSettingUserLocation) private var settingUserLocation = SettingUserLocation.default
        
        private var text: String {
            switch settingUserLocation {
            case .WW:
                return PlaySRGSettingsLocalizedString("Outside Switzerland", comment: "User location setting state")
            case .CH:
                return PlaySRGSettingsLocalizedString("Ignore location", comment: "User location setting state")
            case .`default`:
                return PlaySRGSettingsLocalizedString("Default (IP-based location)", comment: "User location setting state")
            }
        }
        
        private func action() {
            switch settingUserLocation {
            case .WW:
                settingUserLocation = .CH
            case .CH:
                settingUserLocation = .`default`
            case .`default`:
                settingUserLocation = .WW
            }
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("User location", comment: "User location setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(text)
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    private struct SectionWideSupportItem: View {
        @AppStorage(PlaySRGSettingSectionWideSupportEnabled) private var isSectionWideSupportEnabled = false
        
        private func action() {
            isSectionWideSupportEnabled.toggle()
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Section wide support", comment: "Section wide support setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(isSectionWideSupportEnabled ? PlaySRGSettingsLocalizedString("On", comment: "Enabled state label on Apple TV") : PlaySRGSettingsLocalizedString("Off", comment: "Disabled state label on Apple TV"))
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    private struct PosterImagesItem: View {
        private enum SettingPosterImages: String {
            case `default`
            case forced
            case ignored
        }
        
        @AppStorage(PlaySRGSettingPosterImages) private var settingPosterImages = SettingPosterImages.default
        
        private var text: String {
            switch settingPosterImages {
            case .forced:
                return PlaySRGSettingsLocalizedString("Force", comment: "Poster images setting state")
            case .ignored:
                return PlaySRGSettingsLocalizedString("Ignore", comment: "Poster images setting state")
            case .`default`:
                return PlaySRGSettingsLocalizedString("Default (current configuration)", comment: "Poster images setting state")
            }
        }
        
        private func action() {
            switch settingPosterImages {
            case .forced:
                settingPosterImages = .ignored
            case .ignored:
                settingPosterImages = .`default`
            case .`default`:
                settingPosterImages = .forced
            }
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Poster images", comment: "Poster images setting"))
                        .srgFont(.button)
                    Spacer()
                    Text(text)
                        .srgFont(.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    #endif
    
    private struct SupportInformationListItem: View {
        var body: some View {
            Button {
                showText(SupportInformation.generate())
            } label: {
                Text(PlaySRGSettingsLocalizedString("Copy support information", comment: "Label of the button to copy support information"))
                    .srgFont(.button)
                .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    private struct VersionListItem: View {
        var model: ProfileViewModel
        
        var body: some View {
            Button {
                // No action
            } label: {
                HStack {
                    Text(PlaySRGSettingsLocalizedString("Version", comment: "Version introductory label"))
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
