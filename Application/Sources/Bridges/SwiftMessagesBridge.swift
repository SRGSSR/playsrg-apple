//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftMessages
import UIKit

final class SwiftMessagesBridge: NSObject {
    /**
     *  Display a notification message.
     *
     *  @param message             The message to be displayed.
     *  @param accessibilityPrefix Optional clarification prefix used before reading out the message with VoiceOver.
     *  @param image               Optional leading image.
     *  @param backgroundColor     The notification banner color.
     *  @param foregroundColor     Text and image tint color.
     *  @param sticky              The banner has to be removed by the user when set to `true`.
     *
     *  @discussion Provide the most accurate view controller context, as it ensures the notification behaves correctly
     *              for it (i.e. rotates consistently and appears under a parent navigation bar).
     */
    @objc static func show(_ message: String, accessibilityPrefix: String?, image: UIImage?, backgroundColor: UIColor?, foregroundColor: UIColor?, sticky: Bool) {
        SwiftMessages.hideAll()

        let messageView = MessageView.viewFromNib(layout: .cardView)
        messageView.button?.isHidden = true
        messageView.bodyLabel?.font = SRGFont.font(.body)
        messageView.configureDropShadow()

        messageView.configureContent(title: nil, body: message, iconImage: nil, iconText: nil, buttonImage: nil, buttonTitle: nil, buttonTapHandler: nil)
        messageView.configureTheme(backgroundColor: backgroundColor ?? UIColor.white, foregroundColor: foregroundColor ?? UIColor.black)

        messageView.accessibilityPrefix = accessibilityPrefix

        messageView.iconImageView?.image = image
        messageView.iconImageView?.isHidden = (image == nil)

        messageView.tapHandler = { _ in SwiftMessages.hide() }

        var config = SwiftMessages.defaultConfig
        if sticky {
            config.duration = .forever
        } else {
            config.duration = .seconds(seconds: 4)
        }
        config.presentationStyle = .bottom

        // Set a presentation context (with a preference for navigation controllers). A context is required so that
        // the notification rotation behavior matches the one of the currently visible view controller.
        var presentationController = UIApplication.shared.mainTopViewController
        while presentationController?.parent != nil {
            if presentationController is UINavigationController {
                break
            }
            presentationController = presentationController?.parent
        }

        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            config.presentationContext = .window(windowLevel: .normal)
        } else if let presentationController {
            config.presentationContext = .viewController(presentationController)
        }

        // Remark: VoiceOver is supported natively, but with the system language (not the one we might set on the
        //         UIApplication instance)
        SwiftMessages.show(config: config, view: messageView)
    }

    /**
     *  Hide all notification messages.
     */
    @objc static func hideAll() {
        SwiftMessages.hideAll()
    }
}
