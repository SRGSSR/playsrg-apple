//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

extension UIApplication {
    var openTestFlight: (() -> Void)? {
        guard let appStoreAppleId = Bundle.main.object(forInfoDictionaryKey: "AppStoreAppleId") as? String, !appStoreAppleId.isEmpty else { return nil }
        if let url = URL(string: "itms-beta://beta.itunes.apple.com/v1/app/\(appStoreAppleId)"), UIApplication.shared.canOpenURL(url) {
            return {
                UIApplication.shared.open(url)
            }
        } else if let url = URL(string: "https://beta.itunes.apple.com/v1/app/\(appStoreAppleId)"), UIApplication.shared.canOpenURL(url) {
            #if os(iOS)
                return {
                    UIApplication.shared.open(url)
                }
            #else
                return nil
            #endif
        } else {
            return nil
        }
    }
}
