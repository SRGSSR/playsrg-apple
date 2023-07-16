//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import SRGIdentity
import UIKit

@objc final class SupportInformation: NSObject {
    private static func status(for bool: Bool) -> String {
        return bool ? "Yes" : "No"
    }
    
    private static var dateAndTime: String {
        return DateFormatter.play_shortDateAndTime.string(from: Date())
    }
    
    private static var applicationName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    }
    
    private static var applicationIdentifier: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String
    }
    
    private static var applicationVersion: String {
        return Bundle.main.play_friendlyVersionNumber
    }
    
    private static var operatingSystem: String {
        return UIDevice.current.systemName
    }
    
    private static var operatingSystemVersion: String {
        return ProcessInfo.processInfo.operatingSystemVersionString
    }
    
    private static var model: String {
        return UIDevice.current.model
    }
    
    private static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine.0) { p in
            return String(cString: p)
        }
    }
    
    private static var loginStatus: String {
        guard let identityService = SRGIdentityService.current else { return "N/A" }
        return status(for: identityService.isLoggedIn)
    }
    
    private static var continuousAutoplayStatus: String {
        return status(for: ApplicationSettingAutoplayEnabled())
    }
    
    private static var subtitleAvailabilityDisplayed: String {
        return status(for: UserDefaults.standard.bool(forKey: PlaySRGSettingSubtitleAvailabilityDisplayed))
    }
    
    private static var audioDescriptionAvailabilityDisplayed: String {
        return status(for: UserDefaults.standard.bool(forKey: PlaySRGSettingAudioDescriptionAvailabilityDisplayed))
    }
    
    private static var voiceOverEnabled: String {
        return status(for: UIAccessibility.isVoiceOverRunning)
    }
    
#if os(iOS)
    private static var backgroundVideoPlaybackStatus: String {
        return status(for: ApplicationSettingBackgroundVideoPlaybackEnabled())
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
    
    @objc static func generate(toMailBody: Bool = false) -> String {
        var components = [String]()
        
        if toMailBody {
            components.append(NSLocalizedString("Please describe the issue below:", comment: "Mail body header to declare a technical issue"))
            components.append(contentsOf: Array(repeating: "", count: 6))
            components.append("--------------------------------------")
        }
        
        components.append("General information")
        components.append( "-------------------")
        components.append("Date and time: \(dateAndTime)")
        components.append("App name: \(applicationName)")
        components.append("App identifier: \(applicationIdentifier)")
        components.append("App version: \(applicationVersion)")
        components.append("OS: \(operatingSystem)")
        components.append("OS version: \(operatingSystemVersion)")
        components.append("Model: \(model)")
        components.append("Model identifier: \(modelIdentifier)")
        components.append("")
        
        components.append("User settings")
        components.append( "-------------------")
        components.append("Autoplay enabled: \(continuousAutoplayStatus)")
#if os(iOS)
        components.append("Background video playback enabled: \(backgroundVideoPlaybackStatus)")
#endif
        if !ApplicationConfiguration.shared.isSubtitleAvailabilityHidden {
            components.append("Subtitle availability displayed: \(subtitleAvailabilityDisplayed)")
        }
        if !ApplicationConfiguration.shared.isAudioDescriptionAvailabilityHidden {
            components.append("Audio description availability displayed: \(audioDescriptionAvailabilityDisplayed)")
        }
        components.append("VoiceOver enabled: \(voiceOverEnabled)")
        if SRGIdentityService.current != nil {
            components.append("Logged in: \(loginStatus)")
        }
        components.append("")
        
#if os(iOS)
        components.append("Push notification information")
        components.append( "-------------------")
        components.append("Push notifications enabled: \(pushNotificationStatus)")
        components.append("Airship identifier: \(airshipIdentifier)")
        components.append("Device push notification token: \(deviceToken)")
        components.append("Subscribed URNs: \(subscribedShowUrns)")
#endif
        
        return components.joined(separator: "\n")
    }
}
