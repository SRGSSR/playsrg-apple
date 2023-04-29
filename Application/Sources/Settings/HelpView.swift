//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI
import UIKit

// MARK: View

struct HelpView: View {
    @StateObject private var model = HelpModel()
    
    @Accessibility(\.isVoiceOverRunning) private var isVoiceOverRunning
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(description)
                    .srgFont(.body)
                    .foregroundColor(.srgGray96)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                SupportInformationButton(model: model)
                if let openUserSuggestionForm = model.openUserSuggestionForm {
                    UserSuggestionFormButton(action: openUserSuggestionForm)
                }
                EvaluateApplicationButton(model: model)
            }
            .padding(.horizontal, 16)
        }
        .navigationBarTitleDisplayMode(isVoiceOverRunning ? .inline : .large)
        .navigationTitle(NSLocalizedString("Help and Contact", comment: "Help and Contact view title"))
        .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
    }
    
    private var description: String {
        return NSLocalizedString("Need help with something, have a suggestion or want to report a bug?", comment: "Help and Contact view description")
    }
    
    private struct SupportInformationButton: View {
        @ObservedObject var model: HelpModel
        
        @State private var isActionSheetDisplayed = false
        @State private var isMailComposeDisplayed = false
        
        private var canSendMail: Bool {
            return MailComposeView.canSendMail() && model.supportEmailAdress != nil
        }
        
        private func actionSheet() -> ActionSheet {
            var buttons = [Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}]
            if let supportEmailAdress = model.supportEmailAdress {
                buttons.append(Alert.Button.default(Text(String(format: NSLocalizedString("Copy %@", comment: "Label of the button to copy support email to the pasteboard"), supportEmailAdress))) {
                    model.copySupportMailAdress()
                    Banner.show(
                        with: .info,
                        message: NSLocalizedString("Support email has been copied to the pasteboard", comment: "Information message displayed when support information has been copied to the pasteboard"),
                        image: nil,
                        sticky: false
                    )
                })
            }
            buttons.append(Alert.Button.default(Text(NSLocalizedString("Copy support information", comment: "Label of the button to copy support information to the pasteboard"))) {
                model.copySupportInformation()
                Banner.show(
                    with: .info,
                    message: NSLocalizedString("Support information has been copied to the pasteboard", comment: "Information message displayed when support information has been copied to the pasteboard"),
                    image: nil,
                    sticky: false
                )
            })
            if let supportEmailAdress = model.supportEmailAdress {
                return ActionSheet(
                    title: Text(NSLocalizedString("With this device you can not send us feedback", comment: "Missing mail app to support alert title")),
                    message: Text(String(format: NSLocalizedString("Please create an email account or send your feedback directly to %@.", comment: "Missing mail app to support alert description"), supportEmailAdress)),
                    buttons: buttons
                )
            }
            else {
                return ActionSheet(
                    title: Text(NSLocalizedString("Additional informations to share to support team", comment: "Additional informations to support alert title")),
                    buttons: buttons
                )
            }
        }
        
        private func mailComposeView() -> MailComposeView {
            return MailComposeView()
                .toRecipients([model.supportEmailAdress ?? ""])
                .messageBody(SupportInformation.generate(toMailBody: true))
        }
        
        private func action() {
            if canSendMail {
                isMailComposeDisplayed = true
            }
            else {
                isActionSheetDisplayed = true
            }
        }
        
        var body: some View {
            ExpandingButton(label: NSLocalizedString("Report a technical issue", comment: "Label of the button to report a technical issue"), action: action)
                .actionSheet(isPresented: $isActionSheetDisplayed, content: actionSheet)
                .sheet(isPresented: $isMailComposeDisplayed, content: mailComposeView)
        }
    }
    
    private struct UserSuggestionFormButton: View {
        let action: (() -> Void)
        
        var body: some View {
            ExpandingButton(label: NSLocalizedString("A suggestion to share?", comment: "Label of the button to display user suggestion form"), action: action)
        }
    }
    
    private struct EvaluateApplicationButton: View {
        @ObservedObject var model: HelpModel
        
        private func action() {
            model.evaluateApplication()
        }
        
        var body: some View {
            ExpandingButton(label: NSLocalizedString("Evaluate the application", comment: "Label of the button to evaluate the application"), action: action)
        }
    }
    
    /**
     *  Simple wrapper for static list items.
     */
    private struct ListItem<Content: View>: View {
        @ViewBuilder var content: () -> Content
        
        var body: some View {
            content()
        }
    }
}

// MARK: Analytics

private extension HelpView {
    private var analyticsPageTitle: String {
        return AnalyticsPageTitle.helpAndContact.rawValue
    }
    
    private var analyticsPageLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.application.rawValue]
    }
}

// MARK: Preview

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HelpView()
        }
        .navigationViewStyle(.stack)
    }
}
