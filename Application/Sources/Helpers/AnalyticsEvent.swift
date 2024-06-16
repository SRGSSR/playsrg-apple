//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalytics
import SRGDataProviderModel

/**
 *  Play analytics event. Defined for native Play applications only.
 */
struct AnalyticsEvent {
    private let name: String
    private let labels: SRGAnalyticsEventLabels

    /**
     *  Each struct created have expected values.
     *  Use this method to send the event when needed.
     */
    func send() {
        SRGAnalyticsTracker.shared.trackEvent(withName: name, labels: labels)
    }

    static func calendarEventAdd(channel: SRGChannel) -> Self {
        Self(
            name: "calendar_add",
            source: "button",
            value: channel.urn,
            value1: channel.title
        )
    }

    static func continuousPlayback(action: AnalyticsContiniousPlaybackAction, mediaUrn: String) -> Self {
        Self(
            name: "continuous_playback",
            source: action.source,
            type: action.type,
            value: mediaUrn
        )
    }

    static func download(action: AnalyticsListAction, source: AnalyticsListSource, urn: String?) -> Self {
        Self(
            name: action.downloadName,
            source: source.value,
            value: urn
        )
    }

    static func favorite(action: AnalyticsListAction, source: AnalyticsListSource, urn: String?) -> Self {
        Self(
            name: action.favoriteName,
            source: source.value,
            value: urn
        )
    }

    static func googleGast(urn: String) -> Self {
        Self(
            name: "google_cast",
            value: urn
        )
    }

    static func historyRemove(source: AnalyticsListSource, urn: String?) -> Self {
        Self(
            name: "history_remove",
            source: source.value,
            value: urn
        )
    }

    static func identity(action: AnalyticsIdentityAction) -> Self {
        Self(
            name: "identity",
            labels: action.labels
        )
    }

    static func notification(action: AnalyticsNotificationAction, from: AnalyticsNotificationFrom, uid: String, overrideSource: String? = nil, overrideType: String? = nil) -> Self {
        Self(
            name: from.name,
            source: overrideSource ?? from.source,
            type: overrideType ?? action.type,
            value: uid
        )
    }

    static func openUrl(action: AnalyticsOpenUrlAction, source: AnalyticsOpenUrlSource, urn: String?) -> Self {
        Self(
            name: "open_url",
            source: source.value,
            type: action.type,
            value: urn
        )
    }

    static func openHelp(action: AnalyticsOpenHelpAction) -> Self {
        Self(
            name: action.name,
            source: "button"
        )
    }

    static func pictureInPicture(urn: String?) -> Self {
        Self(
            name: "picture_in_picture",
            value: urn
        )
    }

    static func sharing(action: AnalyticsSharingAction, uid: String, mediaContentType: AnalyticsSharingMediaContentType, source: AnalyticsSharingSource, type: String?) -> Self {
        Self(
            name: action.name,
            source: source.value,
            type: type,
            value: uid,
            value1: mediaContentType.value
        )
    }

    static func shortcutItem(action: AnalyticsShortcutItemAction) -> Self {
        Self(
            name: "quick_actions",
            type: action.type
        )
    }

    static func subscription(action: AnalyticsListAction, source: AnalyticsListSource, urn: String?) -> Self {
        Self(
            name: action.subscriptionName,
            source: source.value,
            value: urn
        )
    }

    static func userActivity(action: AnalyticsUserActivityAction, urn: String) -> Self {
        Self(
            name: "user_activity_ios",
            source: "handoff",
            type: action.type,
            value: urn
        )
    }

    static func watchLater(action: AnalyticsListAction, source: AnalyticsListSource, urn: String?) -> Self {
        Self(
            name: action.watchLaterName,
            source: source.value,
            value: urn
        )
    }

    private init(name: String, source: String? = nil, type: String? = nil, value: String? = nil, value1: String? = nil, value2: String? = nil, value3: String? = nil, value4: String? = nil, value5: String? = nil) {
        self.name = name

        let labels = SRGAnalyticsEventLabels()
        labels.source = source
        labels.type = type
        labels.value = value
        labels.extraValue1 = value1
        labels.extraValue2 = value2
        labels.extraValue3 = value3
        labels.extraValue4 = value4
        labels.extraValue5 = value5
        self.labels = labels
    }

    private init(name: String, labels: SRGAnalyticsEventLabels) {
        self.name = name
        self.labels = labels
    }
}

/**
 *  Analytics event compatibility for Objective-C, as a class.
 */
@objc class AnalyticsEventObjC: NSObject {
    private let event: AnalyticsEvent

    /**
     *  Each object created have expected values.
     *  Use this method to send the event when needed.
     */
    @objc func send() {
        event.send()
    }

    @objc class func continuousPlayback(action: AnalyticsContiniousPlaybackAction, mediaUrn: String) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.continuousPlayback(action: action, mediaUrn: mediaUrn))
    }

    @objc class func download(action: AnalyticsListAction, source: AnalyticsListSource, urn: String?) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.download(action: action, source: source, urn: urn))
    }

    @objc class func favorite(action: AnalyticsListAction, source: AnalyticsListSource, urn: String?) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.favorite(action: action, source: source, urn: urn))
    }

    @objc class func googleGast(urn: String) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.googleGast(urn: urn))
    }

    @objc class func identity(action: AnalyticsIdentityAction) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.identity(action: action))
    }

    @objc class func notification(action: AnalyticsNotificationAction, from: AnalyticsNotificationFrom, uid: String, overrideSource: String? = nil, overrideType: String? = nil) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.notification(action: action, from: from, uid: uid, overrideSource: overrideSource, overrideType: overrideType))
    }

    @objc class func openUrl(action: AnalyticsOpenUrlAction, source: AnalyticsOpenUrlSource, urn: String?) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.openUrl(action: action, source: source, urn: urn))
    }

    @objc class func pictureInPicture(urn: String?) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.pictureInPicture(urn: urn))
    }

    @objc class func sharing(action: AnalyticsSharingAction, uid: String, mediaContentType: AnalyticsSharingMediaContentType, source: AnalyticsSharingSource, type: String?) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.sharing(action: action, uid: uid, mediaContentType: mediaContentType, source: source, type: type))
    }

    @objc class func shortcutItem(action: AnalyticsShortcutItemAction) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.shortcutItem(action: action))
    }

    @objc class func userActivity(action: AnalyticsUserActivityAction, urn: String) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.userActivity(action: action, urn: urn))
    }

    @objc class func watchLater(action: AnalyticsListAction, source: AnalyticsListSource, urn: String?) -> AnalyticsEventObjC {
        Self(event: AnalyticsEvent.watchLater(action: action, source: source, urn: urn))
    }

    required init(event: AnalyticsEvent) {
        self.event = event
    }
}

@objc enum AnalyticsListAction: UInt {
    case add
    case remove

    fileprivate var downloadName: String {
        switch self {
        case .add:
            "download_add"
        case .remove:
            "download_remove"
        }
    }

    fileprivate var favoriteName: String {
        switch self {
        case .add:
            "favorite_add"
        case .remove:
            "favorite_remove"
        }
    }

    fileprivate var subscriptionName: String {
        switch self {
        case .add:
            "subscription_add"
        case .remove:
            "subscription_remove"
        }
    }

    fileprivate var watchLaterName: String {
        switch self {
        case .add:
            "watch_later_add"
        case .remove:
            "watch_later_remove"
        }
    }
}

@objc enum AnalyticsListSource: UInt {
    case button
    case contextMenu
    case selection

    fileprivate var value: String {
        switch self {
        case .button:
            "button"
        case .contextMenu:
            "context_menu"
        case .selection:
            "selection"
        }
    }
}

@objc enum AnalyticsContiniousPlaybackAction: UInt {
    case display
    case playAutomatic
    case play
    case cancel

    fileprivate var source: String {
        switch self {
        case .display, .playAutomatic:
            "automatic"
        case .play, .cancel:
            "button"
        }
    }

    fileprivate var type: String {
        switch self {
        case .display:
            "display"
        case .playAutomatic, .play:
            "play_media"
        case .cancel:
            "cancel"
        }
    }
}

@objc enum AnalyticsNotificationAction: UInt {
    case playMedia
    case displayShow
    case alert

    fileprivate var type: String {
        switch self {
        case .playMedia:
            "play_media"
        case .displayShow:
            "display_show"
        case .alert:
            "notification_alert"
        }
    }
}

@objc enum AnalyticsOpenUrlAction: UInt {
    case openPlayApp
    case playMedia
    case displayShow
    case displayPage
    case displayUrl

    fileprivate var type: String {
        switch self {
        case .openPlayApp:
            "open_play_app"
        case .playMedia:
            "play_media"
        case .displayShow:
            "display_show"
        case .displayPage:
            "display_page"
        case .displayUrl:
            "display_url"
        }
    }
}

@objc enum AnalyticsOpenUrlSource: UInt {
    case customURL
    case universalLink

    fileprivate var value: String {
        switch self {
        case .customURL:
            "scheme_url"
        case .universalLink:
            "deep_link"
        }
    }
}

@objc enum AnalyticsOpenHelpAction: UInt {
    case faq
    case technicalIssue
    case feedbackApp
    case evaluateApp

    fileprivate var name: String {
        switch self {
        case .faq:
            "faq_open"
        case .technicalIssue:
            "technical_issue_open"
        case .feedbackApp:
            "feedback_app_open"
        case .evaluateApp:
            "evaluate_app_open"
        }
    }
}

@objc enum AnalyticsIdentityAction: UInt {
    case displayLogin
    case cancelLogin
    case login
    case logout
    case unexpectedLogout

    fileprivate var labels: SRGAnalyticsEventLabels {
        let labels = SRGAnalyticsEventLabels()
        switch self {
        case .displayLogin:
            labels.type = "display_login"
        case .cancelLogin:
            labels.source = "button"
            labels.type = "cancel_login"
        case .login:
            labels.source = "button"
            labels.type = "login"
        case .logout:
            labels.source = "button"
            labels.type = "logout"
        case .unexpectedLogout:
            labels.source = "automatic"
            labels.type = "logout"
        }
        return labels
    }
}

@objc enum AnalyticsNotificationFrom: UInt {
    case application
    case operatingSystem

    fileprivate var name: String {
        switch self {
        case .application:
            "notification_open"
        case .operatingSystem:
            "push_notification_open"
        }
    }

    fileprivate var source: String {
        switch self {
        case .application:
            "notification"
        case .operatingSystem:
            "push_notification"
        }
    }
}

@objc enum AnalyticsSharingAction: UInt {
    case media
    case show
    case page
    case microPage
    case section

    fileprivate var name: String {
        switch self {
        case .media:
            "media_share"
        case .show:
            "show_share"
        case .page:
            "page_share"
        case .microPage:
            "micro_page_share"
        case .section:
            "section_share"
        }
    }
}

@objc enum AnalyticsSharingMediaContentType: UInt {
    case none
    case content
    case contentAtTime
    case currentClip

    fileprivate var value: String? {
        switch self {
        case .content:
            "content"
        case .contentAtTime:
            "content_at_time"
        case .currentClip:
            "current_clip"
        default:
            nil
        }
    }
}

@objc enum AnalyticsSharingSource: UInt {
    case button
    case contextMenu

    fileprivate var value: String {
        switch self {
        case .button:
            "button"
        case .contextMenu:
            "context_menu"
        }
    }
}

@objc enum AnalyticsShortcutItemAction: UInt {
    case favorites
    case downloads
    case history
    case search

    fileprivate var type: String {
        switch self {
        case .favorites:
            "openfavorites"
        case .downloads:
            "opendownloads"
        case .history:
            "openhistory"
        case .search:
            "opensearch"
        }
    }
}

@objc enum AnalyticsUserActivityAction: UInt {
    case playMedia
    case displayShow

    fileprivate var type: String {
        switch self {
        case .playMedia:
            "play_media"
        case .displayShow:
            "display_show"
        }
    }
}
