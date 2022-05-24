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
    return __PlaySRGAccessibilityLocalizedString(key, comment)
}

/**
 *  Return an onboarding localized string from the main bundle.
 */
func PlaySRGOnboardingLocalizedString(_ key: String, comment: String?) -> String {
    return __PlaySRGOnboardingLocalizedString(key, comment)
}
