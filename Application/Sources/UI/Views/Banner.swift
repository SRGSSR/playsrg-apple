//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit
import SRGAppearance
import SRGDataProvider

/**
 *  Supported banner styles.
 */
@objc enum BannerStyle: Int {
    case info
    case warning
    case error
}

/**
 *  Use banners to display messages to the end user.
 */
@objc class Banner: NSObject {
    /**
     *  Show a banner.
     *
     *  @param style   The style to apply.
     *  @param message The message to display.
     *  @param image   Optional leading image.
     *  @param view    The view context for which the banner must be displayed.
     */
    @objc class func show(with style: BannerStyle, message: String?, image: UIImage?, sticky: Bool) {
        guard let message else {
            return
        }
        
        var accessibilityPrefix: String?
        var backgroundColor: UIColor?
        var foregroundColor: UIColor?
        
        switch style {
        case .info:
            accessibilityPrefix = PlaySRGAccessibilityLocalizedString("Information", comment: "Introductory title for information notifications")
            backgroundColor = .srgBlue
            foregroundColor = .white
        case .warning:
            accessibilityPrefix = PlaySRGAccessibilityLocalizedString("Warning", comment: "Introductory title for warning notifications")
            backgroundColor = .orange
            foregroundColor = .black
        case .error:
            accessibilityPrefix = PlaySRGAccessibilityLocalizedString("Error", comment: "Introductory title for error notifications")
            backgroundColor = .srgRed
            foregroundColor = .white
        }
        
        SwiftMessagesBridge.show(message,
                                 accessibilityPrefix: accessibilityPrefix,
                                 image: image,
                                 backgroundColor: backgroundColor,
                                 foregroundColor: foregroundColor,
                                 sticky: sticky)
    }
    
    /**
     *  Hide all banners.
     */
    @objc class func hideAll() {
        SwiftMessagesBridge.hideAll()
    }
}

extension Banner {
    /**
     *  Show a banner for the specified error.
     *
     *  @discussion If no error is provided, the method does nothing.
     */
    @objc class func showError(_ error: NSError?) {
        guard let error else {
            return
        }
        var displayedError = error
        
        // Multiple errors. Pick the first
        if error.domain == SRGNetworkErrorDomain,
           error.code == SRGNetworkErrorCode.multiple.rawValue,
           let subErrors = error.userInfo[SRGNetworkErrorsKey] as? [NSError],
           let subError = subErrors.first {
            displayedError = subError
        }
        
        // Never display cancellation errors
        if displayedError.domain == NSURLErrorDomain, displayedError.code == NSURLErrorCancelled {
            return
        }
        
        show(with: .error, message: displayedError.localizedDescription, image: nil, sticky: false)
    }
    
    /**
     *  Show a banner telling the user that the specified item has been added or removed from favorites.
     *
     *  @discussion If no name is provided, a standard description will be used.
     */
    @objc class func showFavorite(_ isFavorite: Bool, forItemWithName name: String?) {
        var name = name
        if name == nil {
            name = NSLocalizedString("The selected content", comment: "Name of the favorite item, if no title or name to display")
        }
        
        let messageFormatString = isFavorite ?
        NSLocalizedString("%@ has been added to favorites", comment: "Message displayed at the top of the screen when adding a show to favorites. Quotes are managed by the application.") :
        NSLocalizedString("%@ has been deleted from favorites", comment: "Message displayed at the top of the screen when removing a show from favorites. Quotes are managed by the application.")
        let message = String(format: messageFormatString, BannerShortenedName(name))
        let image = UIImage(resource: isFavorite ? .favoriteFull : .favorite)
        show(with: .info, message: message, image: image, sticky: false)
    }
    
    /**
     *  Show a banner telling the user that the specified item has been added or removed from downloads.
     *
     *  @discussion If no name is provided, a standard description will be used.
     */
    @objc class func showDownload(_ downloaded: Bool, forItemWithName name: String?) {
        var name = name
        if name == nil {
            name = NSLocalizedString("The selected content", comment: "Name of the download item, if no title or name to display")
        }
        
        let messageFormatString = downloaded ?
        NSLocalizedString("%@ has been added to downloads", comment: "Message displayed at the top of the screen when adding a media to downloads. Quotes are managed by the application.") :
        NSLocalizedString("%@ has been deleted from downloads", comment: "Message displayed at the top of the screen when removing a media from downloads. Quotes are managed by the application.")
        let message = String(format: messageFormatString, BannerShortenedName(name))
        let image = UIImage(resource: downloaded ? .download : .downloadRemove)
        show(with: .info, message: message, image: image, sticky: false)
    }
    
    /**
     *  Show a banner telling the user that the specified item has been added to or removed from the subscription list.
     *
     *  @discussion If no name is provided, a standard description will be used.
     */
    @objc class func showSubscription(_ subscribed: Bool, forItemWithName name: String?) {
        var name = name
        if name == nil {
            name = NSLocalizedString("The selected content", comment: "Name of the subscription item, if no title or name to display")
        }
        
        let messageFormatString = subscribed ?
        NSLocalizedString("Notifications have been enabled for %@", comment: "Message displayed at the top of the screen when enabling push notifications. Quotes around the content placeholder managed by the application.") :
        NSLocalizedString("Notifications have been disabled for %@", comment: "Message at the top of the screen displayed when disabling push notifications. Quotes around the content placeholder are managed by the application.")
        let message = String(format: messageFormatString, BannerShortenedName(name))
        let image = UIImage(resource: subscribed ? .subscriptionFull : .subscription)
        show(with: .info, message: message, image: image, sticky: false)
    }
    
    /**
     *  Show a banner telling the user that the specified item has been added to or removed from the later list.
     *
     *  @discussion If no name is provided, a standard description will be used.
     */
    @objc class func showWatchLaterAdded(_ added: Bool, forItemWithName name: String?) {
        var name = name
        if name == nil {
            name = NSLocalizedString("The selected content", comment: "Name of the later list item, if no title or name to display")
        }
        
        let messageFormatString = added ?
        NSLocalizedString("%@ has been added to \"Later\"", comment: "Message displayed at the top of the screen when adding a media to the later list. Quotes around the content placeholder are managed by the application.") :
        NSLocalizedString("%@ has been deleted from \"Later\"", comment: "Message displayed at the top of the screen when removing an item from the later list. Quotes around the content placeholder are managed by the application.")
        let message = String(format: messageFormatString, BannerShortenedName(name))
        let image = UIImage(resource: added ? .watchLaterFull : .watchLater)
        show(with: .info, message: message, image: image, sticky: false)
    }
    
    /**
     *  Show a banner telling the user that the specified event has been added to calendar.
     *
     *  @discussion If no name is provided, no banner displayed.
     */
    @objc class func calendarEventAddedWithTitle(_ title: String?) {
        guard let title else {
            return
        }
        
        let messageFormatString = NSLocalizedString("%@ has been added to calendar", comment: "Message displayed at the top of the screen when adding a program to Calendar. Quotes are managed by the application.")
        let message = String(format: messageFormatString, BannerShortenedName(title))
        let image = UIImage(resource: .calendar)
        show(with: .info, message: message, image: image, sticky: false)
    }
}

private func BannerShortenedName(_ name: String?) -> String {
    guard let name else {
        return ""
    }
    
    let maxTitleLength = 60
    if name.count > maxTitleLength {
        return "\"\(name.prefix(maxTitleLength))…\""
    } else {
        return "\"\(name)\""
    }
}
