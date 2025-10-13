//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import MediaAccessibility
import SRGIdentity
import UIKit

@objc final class SupportInformation: NSObject {
    private static func status(for bool: Bool) -> String {
        bool ? "true" : "false"
    }

    private static var dateAndTime: String {
        DateFormatter.play_shortDateAndTime.string(from: Date())
    }

    private static var applicationIdentifier: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String
    }

    private static var applicationVersion: String {
        Bundle.main.play_friendlyVersionNumber
    }

    private static var operatingSystem: String {
        UIDevice.current.systemName
    }

    private static var operatingSystemVersion: String {
        ProcessInfo.processInfo.operatingSystemVersionString
    }

    private static var model: String {
        UIDevice.current.model
    }

    private static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine.0) { p in
            String(cString: p)
        }
    }

    private static var loginStatus: String {
        guard let identityService = SRGIdentityService.current else { return "None" }
        return status(for: identityService.isLoggedIn)
    }

    private static var accountIdentifier: String {
        guard
            let identityService = SRGIdentityService.current, let accountID = identityService.account?.uid else {
            return "None"
        }

        return accountID
    }

    private static var vendorIdentifier: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "None"
    }

    private static var continuousAutoplayStatus: String {
        status(for: ApplicationSettingAutoplayEnabled())
    }

    private static var audioSettings: String {
        ApplicationSettingLastSelectedAudioLanguageCode() ?? "None"
    }

    private static var subtitleSettings: String {
        switch MACaptionAppearanceGetDisplayType(.user) {
        case .automatic:
            return "Automatic"
        case .alwaysOn:
            let languages = MACaptionAppearanceCopySelectedLanguages(.user).takeUnretainedValue() as? [String] ?? []
            guard !languages.isEmpty else { return "On" }
            return "On (preferred languages: \(languages.joined(separator: ", ")))"
        default:
            return "Off"
        }
    }

    private static var subtitleAccessibilitySettings: String {
        guard let characteristics = MACaptionAppearanceCopyPreferredCaptioningMediaCharacteristics(.user).takeRetainedValue() as? [AVMediaCharacteristic],
              !characteristics.isEmpty
        else {
            return "None"
        }
        return characteristics.map(\.rawValue).joined(separator: ", ")
    }

    private static var subtitleAvailabilityDisplayed: String {
        status(for: UserDefaults.standard.bool(forKey: PlaySRGSettingSubtitleAvailabilityDisplayed))
    }

    private static var audioDescriptionAvailabilityDisplayed: String {
        status(for: UserDefaults.standard.bool(forKey: PlaySRGSettingAudioDescriptionAvailabilityDisplayed))
    }

    private static var voiceOverEnabled: String {
        status(for: UIAccessibility.isVoiceOverRunning)
    }

    #if os(iOS)
        private static var backgroundVideoPlaybackStatus: String {
            status(for: ApplicationSettingBackgroundVideoPlaybackEnabled())
        }

        private static var pushNotificationStatus: String {
            guard let pushService = PushService.shared else { return "N/A" }
            return status(for: pushService.isEnabled)
        }

        private static var airshipIdentifier: String {
            guard let pushService = PushService.shared else { return "N/A" }
            return pushService.airshipIdentifier ?? "None"
        }

        private static var deviceToken: String {
            guard let pushService = PushService.shared else { return "N/A" }
            return pushService.deviceToken ?? "None"
        }

        private static var subscribedShowUrns: String {
            guard let pushService = PushService.shared else { return "N/A" }
            let subscribedShowUrns = pushService.subscribedShowURNs
            guard !subscribedShowUrns.isEmpty else { return "None" }
            return pushService.subscribedShowURNs.sorted().joined(separator: ",")
        }
    #endif

    static var applicationName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    }

    @objc static func toQueryItems() -> [URLQueryItem] {
        var items = [URLQueryItem]()

        items.append(URLQueryItem(name: "autoplay", value: continuousAutoplayStatus))

        #if os(iOS)
            items.append(URLQueryItem(name: "background_video_playback", value: backgroundVideoPlaybackStatus))
        #endif

        if !ApplicationConfiguration.shared.isSubtitleAvailabilityHidden {
            items.append(URLQueryItem(name: "subtitle_availability_displayed", value: subtitleAvailabilityDisplayed))
        }

        if !ApplicationConfiguration.shared.isAudioDescriptionAvailabilityHidden {
            items.append(URLQueryItem(name: "ad_availability_displayed", value: audioDescriptionAvailabilityDisplayed))
        }

        items.append(URLQueryItem(name: "most_recent_audio_selection", value: audioSettings))

        if SRGIdentityService.current != nil {
            items.append(URLQueryItem(name: "logged_in", value: loginStatus))
            items.append(URLQueryItem(name: "srg_uuid", value: accountIdentifier))
        }

        items.append(URLQueryItem(name: "subtitle_settings", value: subtitleSettings))
        items.append(URLQueryItem(name: "subtitle_accessibility_settings", value: subtitleAccessibilitySettings))
        items.append(URLQueryItem(name: "voiceover", value: voiceOverEnabled))

        #if os(iOS)
            items.append(URLQueryItem(name: "push_notifications_enabled", value: pushNotificationStatus))
            items.append(URLQueryItem(name: "airship_identifier", value: airshipIdentifier))
            items.append(URLQueryItem(name: "device_push_notification_token", value: deviceToken))
            items.append(URLQueryItem(name: "subscribed_urns", value: subscribedShowUrns))
        #endif

        items.append(URLQueryItem(name: "app_name", value: applicationName))
        items.append(URLQueryItem(name: "app_version", value: applicationVersion))
        items.append(URLQueryItem(name: "os", value: operatingSystem))
        items.append(URLQueryItem(name: "os_version", value: operatingSystemVersion))
        items.append(URLQueryItem(name: "app_identifier", value: applicationIdentifier))
        items.append(URLQueryItem(name: "model", value: model))
        items.append(URLQueryItem(name: "model_identifier", value: modelIdentifier))
        items.append(URLQueryItem(name: "device_id", value: vendorIdentifier))

        return items
    }
}
