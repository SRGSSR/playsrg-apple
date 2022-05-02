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
    
    var body: some View {
        List {
            QualitySection()
            PlaybackSection()
            DisplaySection()
            PermissionsSection()
        }
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
        var body: some View {
            Section {
                Button(NSLocalizedString("Open system settings", comment: "Label of the button opening system settings"), action: openSystemSettings)
            } header: {
                Text(NSLocalizedString("Permissions", comment: "Permissions settings section header"))
            } footer: {
                Text(NSLocalizedString("Local network access must be allowed for Google Cast receiver discovery.", comment: "Permissions settings section footer"))
            }
        }
        
        private func openSystemSettings() {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
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
    
    private func closeBarButtonItem() -> UIBarButtonItem {
        let barButtonItem = UIBarButtonItem(
            image: UIImage(named: "close"),
            landscapeImagePhone: nil,
            style: .done,
            target: self,
            action: #selector(close(_:))
        )
        barButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Close", comment: "Close button label on settings view");
        return barButtonItem
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
        
        title = NSLocalizedString("Settings", comment: "Settings view title")
        navigationItem.leftBarButtonItem = closeBarButtonItem()
    }
    
    @objc func close(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .navigationTitle("Settings")
        }
        .navigationViewStyle(.stack)
    }
}
