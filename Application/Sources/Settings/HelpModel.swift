//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import StoreKit

// MARK: View model

final class HelpModel: ObservableObject {
    var openUserSuggestionForm: (() -> Void)? {
        guard let url = ApplicationConfiguration.shared.userSuggestionUrlWithParameters else { return nil }
        return {
            guard let topViewController = UIApplication.shared.mainTopViewController else { return }
            
            let webViewController = WebViewController(request: URLRequest(url: url), customizationBlock: { webView in
                webView.scrollView.isScrollEnabled = false
            })
            webViewController.title = NSLocalizedString("Your suggestion", comment: "Title displayed at the top of the user suggestion view")
            webViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("OK", comment: "Title of feedback button to close the view"), style: .done, target: self, action: #selector(self.dismissTopViewController(_:)))
            topViewController.present(UINavigationController(rootViewController: webViewController), animated: true)
        }
    }
    
    @objc private func dismissTopViewController(_ barButtonItem: UIBarButtonItem) {
        UIApplication.shared.mainTopViewController?.dismiss(animated: true)
    }
    
    var supportEmailAdress: String? {
        return ApplicationConfiguration.shared.supportEmailAddress
    }
    
    func copySupportMailAdress() {
        UIPasteboard.general.string = supportEmailAdress
    }
    
    func copySupportInformation() {
        UIPasteboard.general.string = SupportInformation.generate()
    }
    
    func evaluateApplication() {
        guard let topViewController = UIApplication.shared.mainTopViewController else { return }
        
        let productViewController = SKStoreProductViewController()
        productViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: ApplicationConfiguration.shared.appStoreProductIdentifier])
        
        topViewController.present(productViewController, animated: true)
    }
}
