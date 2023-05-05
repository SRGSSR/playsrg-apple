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
    fileprivate var messageBody: String?
    
    static func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentationMode: PresentationMode
        
        init(presentation: Binding<PresentationMode>) {
            _presentationMode = presentation
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            presentationMode.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentationMode)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        return viewController(context: context)
    }
    
    func viewController(context: Context?) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        if let coordinator = context?.coordinator {
            viewController.mailComposeDelegate = coordinator
        }
        viewController.setToRecipients(toRecipients)
        if let messageBody {
            viewController.setMessageBody(messageBody, isHTML: false)
        }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
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
    
    func messageBody(_ messageBody: String) -> Self {
        var view = self
        view.messageBody = messageBody
        return view
    }
}
