//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SafariServices
import StoreKit
import SwiftUI

@objc class ProfileHelp: NSObject {
    @objc static func showFeedbackForm() -> Bool {
        guard let url = ApplicationConfiguration.shared.userSuggestionUrlWithParameters else { return false }

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

    @objc static func showSupporByEmail() -> Bool {
        guard let supportEmailAddress = ApplicationConfiguration.shared.supportEmailAddress,
              let tabBarController = UIApplication.shared.mainTabBarController else { return false }

        if MailComposeView.canSendMail() {
            tabBarController.play_top.present(supportEmailMailComposeViewController(supportEmailAddress), animated: true) {
                AnalyticsEvent.openHelp(action: .technicalIssue).send()
            }
        } else {
            tabBarController.play_top.present(supporEmailAlertController(supportEmailAddress), animated: true) {
                AnalyticsEvent.openHelp(action: .technicalIssue).send()
            }
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

    private static var supportEmailAdress: String? {
        ApplicationConfiguration.shared.supportEmailAddress
    }

    private static func copySupportMailAdress() {
        UIPasteboard.general.string = supportEmailAdress
    }

    private static func copySupportInformation() {
        UIPasteboard.general.string = SupportInformation.generate()
    }

    private static func supportEmailMailComposeViewController(_ supportEmailAdress: String) -> UIViewController {
        let subject = "[\(SupportInformation.applicationName)][Apple] \(NSLocalizedString("Report a technical issue", comment: "Subject of the technical issue mail"))"
        let mailComposeView = MailComposeView()
            .toRecipients([supportEmailAdress])
            .subject(subject)
            .messageBody(SupportInformation.generate(toMailBody: true))

        return UIHostingController(rootView: mailComposeView)
    }

    private static func supporEmailAlertController(_ supportEmailAdress: String) -> UIAlertController {
        let alertViewController = UIAlertController(
            title: NSLocalizedString("No mail application found", comment: "Missing mail application alert title"),
            message: String(format: NSLocalizedString("Please contact us at %@", comment: "Missing mail application description"), supportEmailAdress),
            preferredStyle: .alert
        )

        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Title of a cancel button"), style: .cancel))
        alertViewController.addAction(UIAlertAction(title: String(format: NSLocalizedString("Copy %@", comment: "Label of the button to copy support email to the pasteboard"), supportEmailAdress), style: .default, handler: { _ in
            copySupportMailAdress()
            Banner.show(
                with: .info,
                message: NSLocalizedString("Support email has been copied to the pasteboard", comment: "Information message displayed when support information has been copied to the pasteboard"),
                image: nil,
                sticky: false
            )
        }))
        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Copy support information", comment: "Label of the button to copy support information to the pasteboard"), style: .default, handler: { _ in
            copySupportInformation()
            Banner.show(
                with: .info,
                message: NSLocalizedString("Support information has been copied to the pasteboard", comment: "Information message displayed when support information has been copied to the pasteboard"),
                image: nil,
                sticky: false
            )
        }))

        return alertViewController
    }
}
