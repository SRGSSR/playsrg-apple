//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SafariServices
import StoreKit

@objc class ProfileHelp: NSObject {
    @objc static func showFeedbackForm() -> Bool {
        guard let url = ApplicationConfiguration.shared.userSuggestionUrlWithParameters else { return false }
        
        return showSafariViewController(url: url)
    }
    
    @objc static func showFaqs() -> Bool {
        guard let url = ApplicationConfiguration.shared.impressumURL else { return false }
        
        return showSafariViewController(url: url)
    }
    
    @objc static func showStorePage() -> Bool {
        guard let tabBarController = UIApplication.shared.mainTabBarController else { return false }
        
        let productViewController = SKStoreProductViewController()
        productViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: ApplicationConfiguration.shared.appStoreProductIdentifier])
        
        tabBarController.play_top.present(productViewController, animated: true)
        return true
    }
    
    private static func showSafariViewController(url: URL) -> Bool {
        guard let tabBarController = UIApplication.shared.mainTabBarController else { return false }
        
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.dismissButtonStyle = .close
        safariViewController.preferredBarTintColor = UIColor.srgGray16
        safariViewController.preferredControlTintColor = UIColor.srgGrayC7
        
        tabBarController.play_top.present(safariViewController, animated: true)
        return true
    }
}
