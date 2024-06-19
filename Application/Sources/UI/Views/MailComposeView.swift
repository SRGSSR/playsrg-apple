//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import MessageUI
import SwiftUI
import UIKit

// MARK: View

struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode

    fileprivate var toRecipients: [String]?
    fileprivate var subject: String?
    fileprivate var messageBody: String?

    static func canSendMail() -> Bool {
        MFMailComposeViewController.canSendMail()
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentationMode: PresentationMode

        init(presentation: Binding<PresentationMode>) {
            _presentationMode = presentation
        }

        func mailComposeController(_: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
            presentationMode.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(presentation: presentationMode)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        viewController(context: context)
    }

    func viewController(context: Context?) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        if let coordinator = context?.coordinator {
            viewController.mailComposeDelegate = coordinator
        }
        viewController.setToRecipients(toRecipients)
        if let subject {
            viewController.setSubject(subject)
        }
        if let messageBody {
            viewController.setMessageBody(messageBody, isHTML: false)
        }
        return viewController
    }

    func updateUIViewController(_: MFMailComposeViewController, context _: Context) {
        // No updates
    }
}

// MARK: Modifiers

extension MailComposeView {
    func toRecipients(_ toRecipients: [String]) -> Self {
        var view = self
        view.toRecipients = toRecipients
        return view
    }

    func subject(_ subject: String) -> Self {
        var view = self
        view.subject = subject
        return view
    }

    func messageBody(_ messageBody: String) -> Self {
        var view = self
        view.messageBody = messageBody
        return view
    }
}
