//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import StoreKit

@objc class ProfileHelp: NSObject {
    @objc static var feedbackViewController: UIViewController? {
        guard let url = ApplicationConfiguration.shared.userSuggestionUrlWithParameters else { return nil }
        
        let webViewController = WebViewController(request: URLRequest(url: url), customizationBlock: { webView in
            webView.scrollView.isScrollEnabled = false
        })
        webViewController.title = NSLocalizedString("Help us to improve the application", comment: "Title displayed at the top of the feedback view")
        return webViewController
    }
    
    @objc static var faqsViewController: UIViewController? {
        guard let url = ApplicationConfiguration.shared.impressumURL else { return nil }
        
        let webViewController = WebViewController(request: URLRequest(url: url), customizationBlock: nil)
        webViewController.title = NSLocalizedString("FAQs", comment: "Title displayed at the top of the FAQs view")
        return webViewController
    }
    
    @objc static var evaluateApplicationViewController: UIViewController? {
        let productViewController = SKStoreProductViewController()
        productViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: ApplicationConfiguration.shared.appStoreProductIdentifier])
        return productViewController
    }
}
