//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SafariServices
import StoreKit
import SwiftUI

@objc class ProfileHelp: NSObject {
    @objc static func showSupportForm() -> Bool {
        guard let url = ApplicationConfiguration.shared.supportFormUrlWithParameters else { return false }

        return showSafariViewController(url: url) {
            AnalyticsEvent.openHelp(action: .feedbackApp).send()
        }
    }

    @objc static func showFaqs() -> Bool {
        guard let url = ApplicationConfiguration.shared.faqURL else { return false }

        return showSafariViewController(url: url) {
            AnalyticsEvent.openHelp(action: .faq).send()
        }
    }

    @objc static func showStorePage() -> Bool {
        guard let tabBarController = UIApplication.shared.mainTabBarController else { return false }

        let productViewController = SKStoreProductViewController()
        productViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: ApplicationConfiguration.shared.appStoreProductIdentifier])

        tabBarController.play_top.present(productViewController, animated: true) {
            AnalyticsEvent.openHelp(action: .evaluateApp).send()
        }
        return true
    }

    private static func showSafariViewController(url: URL, completion: @escaping () -> Void) -> Bool {
        guard let tabBarController = UIApplication.shared.mainTabBarController else { return false }

        let safariViewController = SFSafariViewController(url: url)
        safariViewController.preferredBarTintColor = UIColor.srgGray16
        safariViewController.preferredControlTintColor = UIColor.srgGrayD2
        safariViewController.modalPresentationStyle = .pageSheet

        tabBarController.play_top.present(safariViewController, animated: true, completion: completion)
        return true
    }
}
