//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI
import UIKit

// MARK: View

struct SettingsView: View {
    @StateObject private var model = SettingsViewModel()
    @FirstResponder private var firstResponder
    
    var body: some View {
        NavigationView {
            List {
                QualitySection()
                PlaybackSection()
                DisplaySection()
                PermissionsSection(model: model)
                ContentSection(model: model)
                InformationSection(model: model)
                AdvancedFeaturesSection(model: model)
            }
            .navigationTitle(NSLocalizedString("Settings", comment: "Settings view title"))
            .toolbar {
                ToolbarItem {
                    Button {
                        firstResponder.sendAction(#selector(SettingsHostViewController.close(_:)))
                    } label: {
                        Text(NSLocalizedString("Done", comment: "Done button title"))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .responderChain(from: firstResponder)
    }
    
    private struct QualitySection: View {
        @AppStorage(PlaySRGSettingHDOverCellularEnabled) var isHDOverCellularEnabled = false
        
        var body: some View {
            Section {
                Toggle(NSLocalizedString("HD over cellular networks", comment: "HD setting label"), isOn: $isHDOverCellularEnabled)
            } header: {
                Text(NSLocalizedString("Quality", comment: "Quality settings section header"))
            } footer: {
                Text(NSLocalizedString("By default the application loads high-definition medias over cellular networks. To avoid possible extra costs this option can be disabled to have the highest quality played only on Wi-Fi networks.", comment: "Quality settings section footer"))
            }
        }
    }
    
    private struct PlaybackSection: View {
        @AppStorage(PlaySRGSettingAutoplayEnabled) var isAutoplayEnabled = false
        @AppStorage(PlaySRGSettingBackgroundVideoPlaybackEnabled) var isBackgroundPlaybackEnabled = false
        
        var body: some View {
            Section {
                Toggle(NSLocalizedString("Autoplay", comment: "Autoplay setting label"), isOn: $isAutoplayEnabled)
            } header: {
                Text(NSLocalizedString("Playback", comment: "Playback settings section header"))
            } footer: {
                Text(NSLocalizedString("When enabled, more content is automatically played after playback of the current content ends.", comment: "Autoplay setting section footer"))
            }
            Section {
                Toggle(NSLocalizedString("Background video playback", comment: "Background video playback setting label"), isOn: $isBackgroundPlaybackEnabled)
            } header: {
                EmptyView()
            } footer: {
                Text(NSLocalizedString("When enabled, video playback continues even when you leave the application.", comment: "Background video playback setting section footer"))
            }
        }
    }
    
    private struct DisplaySection: View {
        @AppStorage(PlaySRGSettingSubtitleAvailabilityDisplayed) var isSubtitleAvailabilityDisplayed = false
        @AppStorage(PlaySRGSettingAudioDescriptionAvailabilityDisplayed) var isAudioDescriptionAvailabilityDisplayed = false
        
        var body: some View {
            Section {
                Toggle(NSLocalizedString("Subtitle availability", comment: "Subtitle availability setting label"), isOn: $isSubtitleAvailabilityDisplayed)
                Toggle(NSLocalizedString("Audio description availability", comment: "Audio description availability setting label"), isOn: $isAudioDescriptionAvailabilityDisplayed)
            } header: {
                Text(NSLocalizedString("Display", comment: "Display settings section header"))
            } footer: {
                Text(NSLocalizedString("Always visible when VoiceOver is active.", comment: "Subtitle availability setting section footer"))
            }
        }
    }
    
    private struct PermissionsSection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            Section {
                Button(NSLocalizedString("Open system settings", comment: "Label of the button opening system settings"), action: model.openSystemSettings)
            } header: {
                Text(NSLocalizedString("Permissions", comment: "Permissions settings section header"))
            } footer: {
                Text(NSLocalizedString("Local network access must be allowed for Google Cast receiver discovery.", comment: "Permissions settings section footer"))
            }
        }
    }
    
    private struct ContentSection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            Section {
                Button(NSLocalizedString("Delete history", comment: "Label of the button to delete the history"), action: model.deleteHistory)
                    .foregroundColor(Color.red)
                Button(NSLocalizedString("Delete favorites", comment: "Label of the button to delete the favorites"), action: model.deleteFavorites)
                    .foregroundColor(Color.red)
                Button(NSLocalizedString("Delete content saved for later", comment: "Label of the button to delete content saved for later"), action: model.deleteWatchLater)
                    .foregroundColor(Color.red)
            } header: {
                Text(NSLocalizedString("Content", comment: "Content settings section header"))
            } footer: {
                if let synchronizationStatus = model.synchronizationStatus {
                    Text(synchronizationStatus)
                }
            }
        }
    }
    
    private struct InformationSection: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            Section {
                NavigationLink {
                    
                } label: {
                    Text(NSLocalizedString("Features", comment: "Label of the button display the features"))
                }
                NavigationLink {
                    
                } label: {
                    Text(NSLocalizedString("What's new", comment: "Label of the button to display what's new information"))
                }
                NavigationLink {
                    
                } label: {
                    Text(NSLocalizedString("Terms and conditions", comment: "Label of the button to display terms and conditions"))
                }
                NavigationLink {
                    
                } label: {
                    Text(NSLocalizedString("Data protection", comment: "Label of the button to display the data protection policy"))
                }
                NavigationLink {
                    
                } label: {
                    Text(NSLocalizedString("Licenses", comment: "Label of the button to display licenses"))
                }
                Button(NSLocalizedString("Source code", comment: "Label of the button to access the source code"), action: model.showSourceCode)
                Button(NSLocalizedString("Become a beta tester", comment: "Label of the button to become beta tester"), action: model.becomeBetaTester)
                VersionCell(model: model)
                Button(NSLocalizedString("Copy support information", comment: "Label of the button to copy support information"), action: model.copySupportInformation)
            } header: {
                Text(NSLocalizedString("Information", comment: "Information section header"))
            }
        }
    }
    
    private struct VersionCell: View {
        @ObservedObject var model: SettingsViewModel
        
        var body: some View {
            HStack {
                Text(NSLocalizedString("Version", comment: "Version label in settings"))
                Spacer()
                Text(model.version)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private struct AdvancedFeaturesSection: View {
        @ObservedObject var model: SettingsViewModel
        
        @AppStorage(PlaySRGSettingPresenterModeEnabled) var isPresenterModeEnabled = false
        @AppStorage(PlaySRGSettingStandaloneEnabled) var isStandaloneEnabled = false
        @AppStorage(PlaySRGSettingSectionWideSupportEnabled) var isSectionWideSupportEnabled = false
        
        var body: some View {
            Section {
                NavigationLink {
                    ServerSelectionView()
                } label: {
                    ServerSelectionCell()
                }
                NavigationLink {
                    UserLocationSelectionView()
                } label: {
                    UserLocationSelectionCell()
                }
                Toggle(NSLocalizedString("Presenter mode", comment: "Presenter mode setting label"), isOn: $isPresenterModeEnabled)
                Toggle(NSLocalizedString("Standalone playback", comment: "Standalone playback setting label"), isOn: $isStandaloneEnabled)
                Toggle(NSLocalizedString("Section wide support", comment: "Section wide support setting label"), isOn: $isSectionWideSupportEnabled)
                NavigationLink {
                    PosterImagesSelectionView()
                } label: {
                    PosterImagesSelectionCell()
                }
                Button(NSLocalizedString("Subscribe to all shows", comment: "Label of the button to subscribe to all shows"), action: model.subscribeToAllShows)
            } header: {
                Text(NSLocalizedString("Advanced features", comment: "Advanced features section header"))
            } footer: {
                Text(NSLocalizedString("This section is only available in nightly and beta versions, and won't appear in the production version.", comment: "Advanced features section footer"))
            }
        }
    }
    
    private struct ServerSelectionCell: View {
        @AppStorage(PlaySRGSettingServiceURL) private var selectedServiceUrlString: String?
        
        private var selectedServer: Server {
            return Server.server(for: selectedServiceUrlString)
        }
        
        var body: some View {
            HStack {
                Text(NSLocalizedString("Server", comment: "Label of the button to access server selection"))
                Spacer()
                Text(selectedServer.title)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private struct ServerSelectionView: View {
        var body: some View {
            List {
                ForEach(Server.servers) { server in
                    ServerCell(server: server)
                }
            }
            .navigationTitle(NSLocalizedString("Server", comment: "Server selection view title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private struct ServerCell: View {
        let server: Server
        
        @AppStorage(PlaySRGSettingServiceURL) var selectedServiceUrlString: String?
        
        private var selectedServer: Server {
            return Server.server(for: selectedServiceUrlString)
        }
        
        var body: some View {
            Button(action: select) {
                HStack {
                    Text(server.title)
                    Spacer()
                    if hasSelected(server) {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .foregroundColor(.primary)
        }
        
        private func hasSelected(_ server: Server) -> Bool {
            if let serviceUrlString = selectedServiceUrlString {
                return server.url.absoluteString == serviceUrlString
            }
            else {
                return server == selectedServer
            }
        }
        
        private func select() {
            selectedServiceUrlString = server.url.absoluteString
        }
    }
    
    private enum UserLocation: String, CaseIterable, Identifiable {
        case `default` = ""
        case WW
        case CH
        
        var id: Self {
            return self
        }
        
        var description: String {
            switch self {
            case .WW:
                return PlaySRGSettingsLocalizedString("Outside Switzerland", comment: "User location setting state")
            case .CH:
                return PlaySRGSettingsLocalizedString("Ignore location", comment: "User location setting state")
            case .`default`:
                return PlaySRGSettingsLocalizedString("Default (IP-based location)", comment: "User location setting state")
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
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private struct UserLocationSelectionView: View {
        var body: some View {
            List {
                ForEach(UserLocation.allCases) { userLocation in
                    LocationCell(userLocation: userLocation)
                }
            }
            .navigationTitle(NSLocalizedString("User location", comment: "User location selection view title"))
            .navigationBarTitleDisplayMode(.inline)
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
    
    private enum PosterImages: String, CaseIterable, Identifiable {
        case `default`
        case forced
        case ignored
        
        var id: Self {
            return self
        }
        
        var description: String {
            switch self {
            case .forced:
                return PlaySRGSettingsLocalizedString("Force", comment: "Poster images setting state")
            case .ignored:
                return PlaySRGSettingsLocalizedString("Ignore", comment: "Poster images setting state")
            case .`default`:
                return PlaySRGSettingsLocalizedString("Default (current configuration)", comment: "Poster images setting state")
            }
        }
    }
    
    private struct PosterImagesSelectionCell: View {
        @AppStorage(PlaySRGSettingPosterImages) private var selectedPosterImages = PosterImages.default
        
        var body: some View {
            HStack {
                Text(NSLocalizedString("Poster images", comment: "Label of the button for poster image format selection"))
                Spacer()
                Text(selectedPosterImages.description)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private struct PosterImagesSelectionView: View {
        var body: some View {
            List {
                ForEach(PosterImages.allCases) { posterImages in
                    PosterImagesCell(posterImages: posterImages)
                }
            }
            .navigationTitle(NSLocalizedString("Poster images", comment: "Poster image format selection view title"))
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: UIKit presentation

class SettingsHostViewController: UIViewController {
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .systemBackground
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hostController = UIHostingController(rootView: SettingsView())
        addChild(hostController)
        
        if let hostView = hostController.view {
            hostView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hostView)
            
            NSLayoutConstraint.activate([
                hostView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                hostView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                hostView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                hostView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        hostController.didMove(toParent: self)
    }
    
    @objc fileprivate func close(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
