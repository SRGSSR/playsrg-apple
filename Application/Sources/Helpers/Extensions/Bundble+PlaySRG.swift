//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

/**
 *  Return an accessibility-oriented localized string from the main bundle.
 */
func PlaySRGAccessibilityLocalizedString(_ key: String, comment: String?) -> String {
    return Bundle.main.localizedString(forKey: key, value: "", table: "Accessibility")
}

/**
 *  Return an onboarding localized string from the main bundle.
 */
func PlaySRGOnboardingLocalizedString(_ key: String, comment: String?) -> String {
    return Bundle.main.localizedString(forKey: key, value: "", table: "Onboarding")
}

/**
 *  Use to avoid user-facing text analyzer warnings.
 *
 *  See https://clang-analyzer.llvm.org/faq.html.
 */
func PlaySRGNonLocalizedString(_ string: String) -> String {
    return string
}

extension Bundle {
    @objc static func PlaySRGAccessibilityLocalizedString(_ key: String, _ comment: String?) -> String {
        return PlaySRG.PlaySRGAccessibilityLocalizedString(key, comment: comment)
    }
    
    var play_friendlyVersionNumber: String {
        let shortVersionString = self.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let marketingVersion = shortVersionString.components(separatedBy: "-").first ?? shortVersionString
        
        let bundleVersion = self.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
        let bundleDisplayNameSuffix = self.infoDictionary?["BundleDisplayNameSuffix"] as? String ?? ""
        let buildName = self.infoDictionary?["BuildName"] as? String ?? ""
        let friendlyBuildName = "\(bundleDisplayNameSuffix)\(buildName.isEmpty ? "" : " \(buildName)")"
        
        var version = "\(marketingVersion) (\(bundleVersion))\(friendlyBuildName)"
        if self.play_isTestFlightDistribution {
            // Unbreakable spaces before / after the separator
            version += " - TF"
        }
        return version
    }
    
    var play_isTestFlightDistribution: Bool {
#if !DEBUG && !APPCENTER
        return (self.appStoreReceiptURL?.path ?? "").contains("sandboxReceipt")
#else
        return false
#endif
    }
    
    var play_isAppStoreRelease: Bool {
#if DEBUG || NIGHTLY || BETA
        return false
#else
        return !self.play_isTestFlightDistribution
#endif
    }
}
