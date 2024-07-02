//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

/**
 *  Return an accessibility-oriented localized string from the main bundle.
 */
func PlaySRGAccessibilityLocalizedString(_ key: String, comment _: String?) -> String {
    Bundle.main.localizedString(forKey: key, value: "", table: "Accessibility")
}

/**
 *  Return an onboarding localized string from the main bundle.
 */
func PlaySRGOnboardingLocalizedString(_ key: String, comment _: String?) -> String {
    Bundle.main.localizedString(forKey: key, value: "", table: "Onboarding")
}

/**
 *  Use to avoid user-facing text analyzer warnings.
 *
 *  See https://clang-analyzer.llvm.org/faq.html.
 */
func PlaySRGNonLocalizedString(_ string: String) -> String {
    string
}

extension Bundle {
    @objc static func PlaySRGAccessibilityLocalizedString(_ key: String, _ comment: String?) -> String {
        PlaySRG.PlaySRGAccessibilityLocalizedString(key, comment: comment)
    }

    var play_friendlyVersionNumber: String {
        let shortVersionString = infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let marketingVersion = shortVersionString.components(separatedBy: "-").first ?? shortVersionString

        let bundleVersion = infoDictionary?["CFBundleVersion"] as? String ?? ""

        let bundleDisplayNameSuffix = infoDictionary?["BundleDisplayNameSuffix"] as? String ?? ""
        let buildName = infoDictionary?["BuildName"] as? String ?? ""
        let friendlyBuildName = "\(bundleDisplayNameSuffix)\(buildName.isEmpty ? "" : " \(buildName)")"

        var version = "\(marketingVersion) (\(bundleVersion))\(friendlyBuildName)"
        if play_isTestFlightDistribution {
            // Unbreakable spaces before / after the separator
            version += " - TF"
        }
        return version
    }

    var play_isTestFlightDistribution: Bool {
        #if !DEBUG
            return (appStoreReceiptURL?.path ?? "").contains("sandboxReceipt")
        #else
            return false
        #endif
    }

    var play_isAppStoreRelease: Bool {
        #if DEBUG || NIGHTLY || BETA
            return false
        #else
            return !play_isTestFlightDistribution
        #endif
    }
}
