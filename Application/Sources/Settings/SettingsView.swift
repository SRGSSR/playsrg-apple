//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#if APPCENTER
import AppCenterDistribute
#endif
#if os(iOS) && (DEBUG || APPCENTER)
import FLEX
#endif
import SRGAppearanceSwift
import SwiftUI
import UIKit

// MARK: View

struct SettingsView: View {
    @StateObject private var model = SettingsViewModel()
    
    @Accessibility(\.isVoiceOverRunning) private var isVoiceOverRunning
    
    var body: some View {
        List {
#if os(tvOS)
            ProfileSection(model: model)
#endif
#if os(iOS)
            QualitySection()
#endif
            PlaybackSection()
            if !(ApplicationConfiguration.shared.isSubtitleAvailabilityHidden && ApplicationConfiguration.shared.isAudioDescriptionAvailabilityHidden) {
                DisplaySection()
            }
#if os(iOS)
            PermissionsSection(model: model)
#endif
            ContentSection(model: model)
#if os(tvOS)
            if model.canDisplayHelpAndContactSection {
                HelpAndContactSection(model: model)
            }
#endif
            if model.canDisplayPrivacySection {
                PrivacySection(model: model)
            }
            InformationSection(model: model)
#if DEBUG || NIGHTLY || BETA
            AdvancedFeaturesSection(model: model)
            ResetSection(model: model)
#endif
#if os(iOS) && (DEBUG || APPCENTER)
            DeveloperSection()
#endif
#if DEBUG || NIGHTLY || BETA
            BottomAdditionalInformationSection(model: model)
#endif
        }
#if os(tvOS)
        .listStyle(GroupedListStyle())
        .play_scrollClipDisabled()
        .frame(maxWidth: LayoutMaxListWidth)
#else
        .navigationBarTitleDisplayMode(isVoiceOverRunning ? .inline : .large)
#endif
        .navigationTitle(NSLocalizedString("Settings", comment: "Settings view title"))
        .tracked(withTitle: analyticsPageTitle, type: AnalyticsPageType.navigationPage.rawValue, levels: analyticsPageLevels)
    }
    
#if os(tvOS)
    // MARK: Profile section
    
    private struct ProfileSection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            PlaySection {
                ForEach(ApplicationSectionInfo.profileApplicationSectionInfos(), id: \.applicationSection) { applicationSectionInfo in
                    Button(action: navigateTo(applicationSectionInfo.applicationSection)) {
                        HStack(spacing: 16) {
                            if let imageName = applicationSectionInfo.imageName {
                                Image(imageName)
                            }
                            Text(applicationSectionInfo.title)
                        }
                    }
                }
                if model.supportsLogin {
                    ProfileButton(model: model)
                }
            } header: {
                Text(NSLocalizedString("Profile", comment: "Profile section header"))
            } footer: {
                model.supportsLogin ? Text(NSLocalizedString("Synchronize favorites, playback history and content saved for later on all devices connected to your account.", comment: "Login benefits description footer")) : nil
            }
        }
        
        private func navigateTo(_ applicationSection: ApplicationSection) -> (() -> Void) {
            return {
                navigateToApplicationSection(applicationSection)
            }
        }
    }
    
    private struct ProfileButton: View {
        @ObservedObject var model: SettingsViewModel
        @State private var isAlertDisplayed = false
        
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
            let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button")))
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
                isAlertDisplayed = true
            }
            else {
                model.login()
            }
        }
        
        var body: some View {
            Button(action: action) {
                HStack(alignment: .center) {
                    Spacer()
                    Text(text)
                        .foregroundColor(model.isLoggedIn ? .red : .primary)
                    Spacer()
                }
            }
            .alert(isPresented: $isAlertDisplayed, content: alert)
        }
    }
#endif
    
    // MARK: Quality section
    
#if os(iOS)
    private struct QualitySection: View {
        @AppStorage(PlaySRGSettingHDOverCellularEnabled) var isHDOverCellularEnabled = false
        
        var body: some View {
            PlaySection {
                Toggle(NSLocalizedString("HD over cellular networks", comment: "HD setting label"), isOn: $isHDOverCellularEnabled)
            } header: {
                Text(NSLocalizedString("Quality", comment: "Quality settings section header"))
            } footer: {
                Text(NSLocalizedString("To avoid possible extra costs this option can be disabled to have the highest quality played only on Wi-Fi networks.", comment: "Quality settings section footer"))
            }
        }
    }
#endif
    
    // MARK: Playback section
    
    private struct PlaybackSection: View {
        @AppStorage(PlaySRGSettingAutoplayEnabled) var isAutoplayEnabled = false
        @AppStorage(PlaySRGSettingBackgroundVideoPlaybackEnabled) var isBackgroundPlaybackEnabled = false
        
        var body: some View {
            PlaySection {
                Toggle(NSLocalizedString("Autoplay", comment: "Autoplay setting label"), isOn: $isAutoplayEnabled)
            } header: {
                Text(NSLocalizedString("Playback", comment: "Playback settings section header"))
            } footer: {
                Text(NSLocalizedString("More content is automatically played after playback of the current content ends.", comment: "Autoplay setting section footer"))
            }
#if os(iOS)
            PlaySection {
                Toggle(NSLocalizedString("Background video playback", comment: "Background video playback setting label"), isOn: $isBackgroundPlaybackEnabled)
            } header: {
                EmptyView()
            } footer: {
                Text(NSLocalizedString("Video playback continues even when you leave the application.", comment: "Background video playback setting section footer"))
            }
#endif
        }
    }
    
    // MARK: Display section
    
    private struct DisplaySection: View {
        @AppStorage(PlaySRGSettingSubtitleAvailabilityDisplayed) var isSubtitleAvailabilityDisplayed = false
        @AppStorage(PlaySRGSettingAudioDescriptionAvailabilityDisplayed) var isAudioDescriptionAvailabilityDisplayed = false
        
        var body: some View {
            PlaySection {
                if !ApplicationConfiguration.shared.isSubtitleAvailabilityHidden {
                    Toggle(NSLocalizedString("Subtitle availability", comment: "Subtitle availability setting label"), isOn: $isSubtitleAvailabilityDisplayed)
                }
                if !ApplicationConfiguration.shared.isAudioDescriptionAvailabilityHidden {
                    Toggle(NSLocalizedString("Audio description availability", comment: "Audio description availability setting label"), isOn: $isAudioDescriptionAvailabilityDisplayed)
                }
            } header: {
                Text(NSLocalizedString("Display", comment: "Display settings section header"))
            } footer: {
                Text(NSLocalizedString("Always visible when VoiceOver is active.", comment: "Subtitle availability setting section footer"))
            }
        }
    }
    
    // MARK: Permissions section
    
#if os(iOS)
    private struct PermissionsSection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            PlaySection {
                Button(NSLocalizedString("Open system settings", comment: "Label of the button opening system settings"), action: model.openSystemSettings)
            } header: {
                Text(NSLocalizedString("Permissions", comment: "Permissions settings section header"))
            } footer: {
                Text(NSLocalizedString("Local network access must be allowed for Google Cast receiver discovery.", comment: "Permissions settings section footer"))
            }
        }
    }
#endif
    
    // MARK: Content section
    
    private struct ContentSection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            PlaySection {
                FavoritesRemovalButton(model: model)
                HistoryRemovalButton(model: model)
                WatchLaterRemovalButton(model: model)
            } header: {
                Text(NSLocalizedString("Content", comment: "Content settings section header"))
            } footer: {
                if let synchronizationStatus = model.synchronizationStatus {
                    Text(synchronizationStatus)
                }
            }
        }
        
        private struct FavoritesRemovalButton: View {
            @ObservedObject var model: SettingsViewModel
            @State private var isAlertDisplayed = false
            
            private func alert() -> Alert {
                let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button")))
                let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                    model.removeFavorites()
                }
                if model.isLoggedIn {
                    return Alert(
                        title: Text(NSLocalizedString("Delete favorites", comment: "Title of the message displayed when the user is about to delete all favorites")),
                        message: Text(NSLocalizedString("Favorites and notification subscriptions will be deleted on all devices connected to your account.", comment: "Message displayed when the user is about to delete all favorites")),
                        primaryButton: primaryButton,
                        secondaryButton: secondaryButton
                    )
                }
                else {
                    return Alert(
                        title: Text(NSLocalizedString("Delete favorites", comment: "Title of the message displayed when the user is about to delete all favorites")),
                        primaryButton: primaryButton,
                        secondaryButton: secondaryButton
                    )
                }
            }
            
            private func action() {
                if model.hasFavorites {
                    isAlertDisplayed = true
                }
            }
            
            var body: some View {
                Button(action: action) {
                    Text(NSLocalizedString("Delete favorites", comment: "Delete favorites button title"))
                        .foregroundColor(model.hasFavorites ? .red : Color.play_sectionSecondary)
                }
                .disabled(!model.hasFavorites)
                .alert(isPresented: $isAlertDisplayed, content: alert)
            }
        }
        
        private struct HistoryRemovalButton: View {
            @ObservedObject var model: SettingsViewModel
            @State private var isAlertDisplayed = false
            
            private func alert() -> Alert {
                let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button")))
                let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                    model.removeHistory()
                }
                if model.isLoggedIn {
                    return Alert(
                        title: Text(NSLocalizedString("Delete history", comment: "Title of the message displayed when the user is about to delete the history")),
                        message: Text(NSLocalizedString("The history will be deleted on all devices connected to your account.", comment: "Message displayed when the user is about to delete the history")),
                        primaryButton: primaryButton,
                        secondaryButton: secondaryButton
                    )
                }
                else {
                    return Alert(
                        title: Text(NSLocalizedString("Delete history", comment: "Title of the message displayed when the user is about to delete the history")),
                        primaryButton: primaryButton,
                        secondaryButton: secondaryButton
                    )
                }
            }
            
            private func action() {
                if model.hasHistoryEntries {
                    isAlertDisplayed = true
                }
            }
            
            var body: some View {
                Button(action: action) {
                    Text(NSLocalizedString("Delete history", comment: "Delete history button title"))
                        .foregroundColor(model.hasHistoryEntries ? .red : Color.play_sectionSecondary)
                }
                .disabled(!model.hasHistoryEntries)
                .alert(isPresented: $isAlertDisplayed, content: alert)
            }
        }
        
        private struct WatchLaterRemovalButton: View {
            @ObservedObject var model: SettingsViewModel
            @State private var isAlertDisplayed = false
            
            private func alert() -> Alert {
                let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button")))
                let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                    model.removeWatchLaterItems()
                }
                if model.isLoggedIn {
                    return Alert(
                        title: Text(NSLocalizedString("Delete content saved for later", comment: "Title of the message displayed when the user is about to delete content saved for later")),
                        message: Text(NSLocalizedString("Content saved for later will be deleted on all devices connected to your account.", comment: "Message displayed when the user is about to delete content saved for later")),
                        primaryButton: primaryButton,
                        secondaryButton: secondaryButton
                    )
                }
                else {
                    return Alert(
                        title: Text(NSLocalizedString("Delete content saved for later", comment: "Title of the message displayed when the user is about to delete content saved for later")),
                        primaryButton: primaryButton,
                        secondaryButton: secondaryButton
                    )
                }
            }
            
            private func action() {
                if model.hasWatchLaterItems {
                    isAlertDisplayed = true
                }
            }
            
            var body: some View {
                Button(action: action) {
                    Text(NSLocalizedString("Delete content saved for later", comment: "Title of the button to delete content saved for later"))
                        .foregroundColor(model.hasWatchLaterItems ? .red : Color.play_sectionSecondary)
                }
                .disabled(!model.hasWatchLaterItems)
                .alert(isPresented: $isAlertDisplayed, content: alert)
            }
        }
    }
    
    // MARK: Privacy section
    
    private struct PrivacySection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            PlaySection {
                if let showDataProtection = model.showDataProtection {
                    Button(NSLocalizedString("Data protection", comment: "Label of the button to display the data protection policy"), action: showDataProtection)
                }
                if let showPrivacySettings = model.showPrivacySettings {
                    Button(NSLocalizedString("Privacy settings", comment: "Label of the button to display the privacy settings"), action: showPrivacySettings)
                }
            } header: {
                Text(NSLocalizedString("Privacy", comment: "Privacy section header"))
            }
        }
    }
    
    // MARK: Information section
    
    private struct InformationSection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            PlaySection {
#if os(iOS)
                NavigationLink {
                    FeaturesView()
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Text(NSLocalizedString("Features", comment: "Label of the button display the features"))
                }
                NavigationLink {
                    WhatsNewView(url: model.whatsNewURL)
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Text(NSLocalizedString("What's new", comment: "Label of the button to display what's new information"))
                }
                if let showImpressum = model.showImpressum {
                    Button(NSLocalizedString("Help and impressum", comment: "Label of the button to display help and impressum"), action: showImpressum)
                }
                if let showTermsAndConditions = model.showTermsAndConditions {
                    Button(NSLocalizedString("Terms and conditions", comment: "Label of the button to display terms and conditions"), action: showTermsAndConditions)
                }
                if let showSourceCode = model.showSourceCode {
                    Button(NSLocalizedString("Source code", comment: "Label of the button to access the source code"), action: showSourceCode)
                }
                if let becomeBetaTester = model.becomeBetaTester {
                    Button(NSLocalizedString("Become a beta tester", comment: "Label of the button to become beta tester"), action: becomeBetaTester)
                }
#endif
                VersionCell(model: model)
            } header: {
                Text(NSLocalizedString("Information", comment: "Information section header"))
            }
        }
        
        fileprivate struct VersionCell: View {
            @ObservedObject var model: SettingsViewModel
            
            var body: some View {
                ListItem {
                    HStack {
                        Text(NSLocalizedString("Version", comment: "Version label in settings"))
                        Spacer()
                        Text(model.version)
                            .foregroundColor(Color.play_sectionSecondary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                    }
                }
            }
        }
    }
    
#if os(tvOS)
    // MARK: Help and Contact section
    
    private struct HelpAndContactSection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            PlaySection {
                if let showSupportInformation = model.showSupportInformation {
                    SupportInformationButton(showSupportInformation: showSupportInformation)
                }
            } header: {
                Text(NSLocalizedString("Help and contact", comment: "Help and contact section header"))
            }
        }
        
        private struct SupportInformationButton: View {
            let showSupportInformation: (() -> Void)
            
            @State private var isActionSheetDisplayed = false
            @State private var isMailComposeDisplayed = false
            
            var body: some View {
                Button(action: showSupportInformation) {
                    Text(NSLocalizedString("Report a technical issue", comment: "Label of the button to present technical issue report instructions"))
                }
            }
        }
    }
#endif
    
    // MARK: Advanced features section
    
#if DEBUG || NIGHTLY || BETA
    private struct AdvancedFeaturesSection: View {
        @ObservedObject var model: SettingsViewModel
        
        @AppStorage(PlaySRGSettingPresenterModeEnabled) var isPresenterModeEnabled = false
        @AppStorage(PlaySRGSettingStandaloneEnabled) var isStandaloneEnabled = false
        @AppStorage(PlaySRGSettingSectionWideSupportEnabled) var isSectionWideSupportEnabled = false
        @AppStorage(PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled) var isAlwaysAskUserConsentAtLaunchEnabled = false
        
        var body: some View {
            PlaySection {
                NextLink {
                    ServiceSelectionView()
#if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
#endif
                } label: {
                    ServiceSelectionCell()
                }
                NextLink {
                    UserLocationSelectionView()
#if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
#endif
                } label: {
                    UserLocationSelectionCell()
                }
                Toggle(NSLocalizedString("Presenter mode", comment: "Presenter mode setting label"), isOn: $isPresenterModeEnabled)
                Toggle(NSLocalizedString("Standalone playback", comment: "Standalone playback setting label"), isOn: $isStandaloneEnabled)
                Toggle(NSLocalizedString("Section wide support", comment: "Section wide support setting label"), isOn: $isSectionWideSupportEnabled)
                NextLink {
                    PosterImagesSelectionView()
#if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
#endif
                } label: {
                    PosterImagesSelectionCell()
                }
                Toggle(NSLocalizedString("Always ask user consent at launch", comment: "Always ask user consent at launch setting label"), isOn: $isAlwaysAskUserConsentAtLaunchEnabled)
#if os(iOS) && APPCENTER
                VersionsAndReleaseNotesButton()
#endif
            } header: {
                Text(NSLocalizedString("Advanced features", comment: "Advanced features section header"))
            } footer: {
                Text(NSLocalizedString("This section is only available in nightly and beta versions, and won't appear in the production version.", comment: "Advanced features section footer"))
            }
        }
        
        private struct ServiceSelectionCell: View {
            @AppStorage(PlaySRGSettingServiceIdentifier) private var selectedServiceId: String?
            
            private var selectedService: Service {
                return Service.service(forId: selectedServiceId)
            }
            
            var body: some View {
                HStack {
                    Text(NSLocalizedString("Server", comment: "Label of the button to access server selection"))
                    Spacer()
                    Text(selectedService.name)
                        .foregroundColor(Color.play_sectionSecondary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
            }
        }
        
        private struct UserLocationSelectionCell: View {
            @AppStorage(PlaySRGSettingUserLocation) private var selectedUserLocation = UserLocation.default
            
            var body: some View {
                HStack {
                    Text(NSLocalizedString("User location", comment: "Label of the button for user location selection"))
                    Spacer()
                    Text(selectedUserLocation.description)
                        .foregroundColor(Color.play_sectionSecondary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
            }
        }
        
#if os(iOS) && APPCENTER
        private struct VersionsAndReleaseNotesButton: View {
            @State private var isSheetDisplayed = false
            
            private var appCenterUrl: URL? {
                guard let appCenterUrlString = Bundle.main.object(forInfoDictionaryKey: "AppCenterURL") as? String, !appCenterUrlString.isEmpty else {
                    return nil
                }
                return URL(string: appCenterUrlString)
            }
            
            var body: some View {
                if let appCenterUrl {
                    Button(NSLocalizedString("Versions and release notes", comment: "Label of the button to access release notes and download internal builds (App Center)"), action: action)
                        .sheet(isPresented: $isSheetDisplayed) {
                            SafariView(url: appCenterUrl)
                                .ignoresSafeArea()
                        }
                }
            }
            
            private func action() {
                UserDefaults.standard.removeObject(forKey: "MSAppCenterPostponedTimestamp")
                Distribute.checkForUpdate()
                isSheetDisplayed = true
            }
        }
#endif
        
        private struct PosterImagesSelectionCell: View {
            @AppStorage(PlaySRGSettingPosterImages) private var selectedPosterImages = PosterImages.default
            
            var body: some View {
                HStack {
                    Text(NSLocalizedString("Poster images", comment: "Label of the button for poster image format selection"))
                    Spacer()
                    Text(selectedPosterImages.description)
                        .foregroundColor(Color.play_sectionSecondary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
            }
        }
        
        private struct ServiceSelectionView: View {
            var body: some View {
                List {
                    ForEach(Service.services) { service in
                        ServiceCell(service: service)
                    }
                }
                .srgFont(.body)
#if os(tvOS)
                .listStyle(GroupedListStyle())
                .play_scrollClipDisabled()
                .frame(maxWidth: LayoutMaxListWidth)
#endif
                .navigationTitle(NSLocalizedString("Server", comment: "Server selection view title"))
            }
        }
        
        private struct ServiceCell: View {
            let service: Service
            
            @AppStorage(PlaySRGSettingServiceIdentifier) var selectedServiceId: String?
            
            var body: some View {
                Button(action: select) {
                    HStack {
                        Text(service.name)
                        Spacer()
                        if isSelected() {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            
            private func isSelected() -> Bool {
                if let selectedServiceId {
                    return service.id == selectedServiceId
                }
                else {
                    return service == .production
                }
            }
            
            private func select() {
                selectedServiceId = service.id
            }
        }
        
        private struct UserLocationSelectionView: View {
            var body: some View {
                List {
                    ForEach(UserLocation.allCases) { userLocation in
                        LocationCell(userLocation: userLocation)
                    }
                }
                .srgFont(.body)
#if os(tvOS)
                .listStyle(GroupedListStyle())
                .play_scrollClipDisabled()
                .frame(maxWidth: LayoutMaxListWidth)
#endif
                .navigationTitle(NSLocalizedString("User location", comment: "User location selection view title"))
            }
        }
        
        private struct LocationCell: View {
            let userLocation: UserLocation
            
            @AppStorage(PlaySRGSettingUserLocation) private var selectedUserLocation = UserLocation.default
            
            var body: some View {
                Button(action: select) {
                    HStack {
                        Text(userLocation.description)
                        Spacer()
                        if userLocation == selectedUserLocation {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            
            private func select() {
                selectedUserLocation = userLocation
            }
        }
        
        // MARK: Poster images selection
        
        private struct PosterImagesSelectionView: View {
            var body: some View {
                List {
                    ForEach(PosterImages.allCases) { posterImages in
                        PosterImagesCell(posterImages: posterImages)
                    }
                }
                .srgFont(.body)
#if os(tvOS)
                .listStyle(GroupedListStyle())
                .play_scrollClipDisabled()
                .frame(maxWidth: LayoutMaxListWidth)
#endif
                .navigationTitle(NSLocalizedString("Poster images", comment: "Poster image format selection view title"))
            }
        }
        
        private struct PosterImagesCell: View {
            let posterImages: PosterImages
            
            @AppStorage(PlaySRGSettingPosterImages) private var selectedPosterImages = PosterImages.default
            
            var body: some View {
                Button(action: select) {
                    HStack {
                        Text(posterImages.description)
                        Spacer()
                        if posterImages == selectedPosterImages {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            
            private func select() {
                selectedPosterImages = posterImages
            }
        }
    }
#endif
    
    // MARK: Reset section
    
#if DEBUG || NIGHTLY || BETA
    private struct ResetSection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            PlaySection {
                Button(NSLocalizedString("Clear web cache", comment: "Label of the button to clear the web cache"), action: model.clearWebCache)
                    .foregroundColor(.red)
                Button(NSLocalizedString("Clear vector image cache", comment: "Label of the button to clear the vector image cache"), action: model.clearVectorImageCache)
                    .foregroundColor(.red)
                Button(NSLocalizedString("Clear all contents", comment: "Label of the button to clear all contents"), action: model.clearAllContents)
                    .foregroundColor(.red)
                Button(NSLocalizedString("Simulate memory warning", comment: "Label of the button to simulate a memory warning"), action: model.simulateMemoryWarning)
            } header: {
                Text(NSLocalizedString("Reset", comment: "Reset section header"))
            } footer: {
                Text(NSLocalizedString("This section is only available in nightly and beta versions, and won't appear in the production version.", comment: "Reset section footer"))
            }
        }
    }
#endif
    
    // MARK: Developer section
    
#if os(iOS) && (DEBUG || APPCENTER)
    private struct DeveloperSection: View {
        var body: some View {
            PlaySection {
                Button(NSLocalizedString("Enable / disable FLEX", comment: "Label of the button to toggle FLEX"), action: toggleFlex)
            } header: {
                Text(NSLocalizedString("Developer", comment: "Developer section header"))
            } footer: {
                Text(NSLocalizedString("This section is only available in nightly and beta versions, and won't appear in the production version.", comment: "Reset section footer"))
            }
        }
        
        private func toggleFlex() {
            FLEXManager.shared.toggleExplorer()
        }
    }
#endif
    
    // MARK: Bottom additional information section

#if DEBUG || NIGHTLY || BETA
    private struct BottomAdditionalInformationSection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            PlaySection {
                if let checkForUpdates = model.checkForUpdates {
                    Button(NSLocalizedString("Check for updates", comment: "Label of the button to open Apple Testflight application and see other builds to test"), action: checkForUpdates)
                }
                InformationSection.VersionCell(model: model)
            } header: {
                Text(NSLocalizedString("Information", comment: "Information section header"))
            } footer: {
                Text(NSLocalizedString("This section is only available in nightly and beta versions, and won't appear in the production version.", comment: "Bottom additional information section footer"))
            }
        }
    }
#endif
    
    // MARK: Presentation
    
    /**
     *  Presents with a modal sheet on tvOS (better), with a navigation level otherwise.
     */
    private struct NextLink<Destination: View, Label: View>: View {
        @ViewBuilder var destination: () -> Destination
        @ViewBuilder var label: () -> Label
        
#if os(tvOS)
        @State private var isPresented = false
#endif
        
        var body: some View {
#if os(tvOS)
            Button(action: action, label: label)
                .sheet(isPresented: $isPresented, content: destination)
#else
            NavigationLink(destination: {
                destination()
                    .navigationBarTitleDisplayMode(.inline)
            }, label: label)
#endif
        }
        
#if os(tvOS)
        private func action() {
            isPresented = true
        }
#endif
    }
    
    /**
     *  Simple wrapper for static list items.
     */
    private struct ListItem<Content: View>: View {
        @ViewBuilder var content: () -> Content
        
        var body: some View {
#if os(tvOS)
            Button(action: { /* Nothing, just to make the item focusable */ }, label: content)
#else
            content()
#endif
        }
    }
}

// MARK: Analytics

private extension SettingsView {
    private var analyticsPageTitle: String {
        return AnalyticsPageTitle.settings.rawValue
    }
    
    private var analyticsPageLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.application.rawValue]
    }
}

// MARK: Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
        .navigationViewStyle(.stack)
    }
}
