//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalytics
import SRGDataProvider

/**
 *  Play analytics hidden event. Defined for native Play applications only.
 */
struct AnalyticsHiddenEvent {
    private let name: String
    private let labels: SRGAnalyticsHiddenEventLabels
    
    /**
     *  Each struct created have expected values.
     *  Use this method to send the event when needed.
     */
    func send() {
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
    }
    
    static func calendarEventAdd(channel: SRGChannel) -> AnalyticsHiddenEvent {
        return Self(
            name: .calendarAdd,
            source: AnalyticsEventSource.button.value,
            value: channel.urn,
            value1: channel.title
        )
    }
    
    static func continuousPlayback(action: AnalyticsContiniousPlaybackAction, mediaUrn: String, recommendationUid: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: .continuousPlayback,
            source: action.source.value,
            type: action.type.rawValue,
            value: mediaUrn,
            value1: recommendationUid
        )
    }
    
    static func download(action: AnalyticsListAction, source: AnalyticsEventSource, urn: String? = nil) -> AnalyticsHiddenEvent {
        return Self(
            name: action.downloadName,
            source: source.value,
            value: urn
        )
    }
    
    static func favorite(action: AnalyticsListAction, source: AnalyticsEventSource, urn: String? = nil) -> AnalyticsHiddenEvent {
        return Self(
            name: action.favoriteName,
            source: source.value,
            value: urn
        )
    }
    
    static func googleGast(urn: String) -> AnalyticsHiddenEvent {
        return Self(
            name: .googleCast,
            value: urn
        )
    }
    
    static func historyRemove(source: AnalyticsEventSource, urn: String? = nil) -> AnalyticsHiddenEvent {
        return Self(
            name: .historyRemove,
            source: source.value,
            value: urn
        )
    }
    
    static func identity(action: AnalyticsIdentityAction) -> AnalyticsHiddenEvent {
        return Self(
            name: .identity,
            labels: action.labels
        )
    }
    
    static func notification(action: AnalyticsNotificationAction, from: AnalyticsNotificationFrom, uid: String, overrideSource: String? = nil, overrideType: String? = nil) -> AnalyticsHiddenEvent {
        return Self(
            name: from.name,
            source: overrideSource ?? from.source.value,
            type: overrideType ?? action.type.rawValue,
            value: uid
        )
    }
    
    static func openUrl(action: AnalyticsOpenUrlAction, source: AnalyticsEventSource, urn: String?, sourceApplication: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: .openUrl,
            source: source.value,
            type: action.type.rawValue,
            value: urn,
            value1: sourceApplication
        )
    }
    
    static func pictureInPicture(urn: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: .pictureInPicture,
            value: urn
        )
    }
    
    static func sharing(action: AnalyticsSharingAction, uid: String, sharedMediaType: AnalyticsSharedMediaType, source: AnalyticsEventSource, type: String?) -> AnalyticsHiddenEvent {
            return Self(
                name: action.name,
                source: source.value,
                type: type,
                value: uid,
                value1: sharedMediaType.value
            )
    }
    
    static func shortcutItem(action: AnalyticsShortcutItemAction) -> AnalyticsHiddenEvent {
        return Self(
            name: .quickActions,
            type: action.type
        )
    }
    
    static func subscription(action: AnalyticsListAction, source: AnalyticsEventSource, urn: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: action.subscriptionName,
            source: source.value,
            value: urn
        )
    }
    
    static func userActivity(action: AnalyticsUserActivityAction, urn: String) -> AnalyticsHiddenEvent {
        return Self(
            name: .userActivityIos,
            source: "handoff",
            type: action.type.rawValue,
            value: urn
        )
    }
    
    static func watchLater(action: AnalyticsListAction, source: AnalyticsEventSource, urn: String? = nil) -> AnalyticsHiddenEvent {
        return Self(
            name: action.watchLaterName,
            source: source.value,
            value: urn
        )
    }
    
    private init(name: AnalyticsHiddenEventName, source: String? = nil, type: String? = nil, value: String? = nil, value1: String? = nil, value2: String? = nil, value3: String? = nil, value4: String? = nil, value5: String? = nil) {
        self.name = name.rawValue
        
        let labels = SRGAnalyticsHiddenEventLabels()
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
    
    private init(name: AnalyticsHiddenEventName, labels: SRGAnalyticsHiddenEventLabels) {
        self.name = name.rawValue
        self.labels = labels
    }
}

/**
 *  Objective-C Play analytics hidden events compatibility.
 */
@objc class AnalyticsHiddenEvents: NSObject {
    private let event: AnalyticsHiddenEvent
    
    /**
     *  Each object created have expected values.
     *  Use this method to send the event when needed.
     */
    @objc func send() {
        self.event.send()
    }
    
    @objc class func continuousPlayback(action: AnalyticsContiniousPlaybackAction, mediaUrn: String, recommendationUid: String?) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.continuousPlayback(action: action, mediaUrn: mediaUrn, recommendationUid: recommendationUid))
    }
    
    @objc class func download(action: AnalyticsListAction, source: AnalyticsEventSource, urn: String? = nil) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.download(action: action, source: source, urn: urn))
    }
    
    @objc class func favorite(action: AnalyticsListAction, source: AnalyticsEventSource, urn: String? = nil) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.favorite(action: action, source: source, urn: urn))
    }
    
    @objc class func googleGast(urn: String) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.googleGast(urn: urn))
    }
    
    @objc class func identity(action: AnalyticsIdentityAction) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.identity(action: action))
    }
    
    @objc class func notification(action: AnalyticsNotificationAction, from: AnalyticsNotificationFrom, uid: String, overrideSource: String? = nil, overrideType: String? = nil) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.notification(action: action, from: from, uid: uid, overrideSource: overrideSource, overrideType: overrideType))
    }
    
    @objc class func openUrl(action: AnalyticsOpenUrlAction, source: AnalyticsEventSource, urn: String?, sourceApplication: String?) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.openUrl(action: action, source: source, urn: urn, sourceApplication: sourceApplication))
    }
    
    @objc class func pictureInPicture(urn: String?) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.pictureInPicture(urn: urn))
    }
    
    @objc class func sharing(action: AnalyticsSharingAction, uid: String, sharedMediaType: AnalyticsSharedMediaType, source: AnalyticsEventSource, type: String?) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.sharing(action: action, uid: uid, sharedMediaType: sharedMediaType, source: source, type: type))
    }
    
    @objc class func shortcutItem(action: AnalyticsShortcutItemAction) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.shortcutItem(action: action))
    }
    
    @objc class func userActivity(action: AnalyticsUserActivityAction, urn: String) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.userActivity(action: action, urn: urn))
    }
    
    @objc class func watchLater(action: AnalyticsListAction, source: AnalyticsEventSource, urn: String? = nil) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.watchLater(action: action, source: source, urn: urn))
    }
    
    required init(event: AnalyticsHiddenEvent) {
        self.event = event
    }
}

@objc enum AnalyticsListAction: UInt {
    case add
    case remove
    
    fileprivate var downloadName: AnalyticsHiddenEventName {
        switch self {
        case .add:
            return .downloadAdd
        case .remove:
            return .downloadRemove
        }
    }
    
    fileprivate var favoriteName: AnalyticsHiddenEventName {
        switch self {
        case .add:
            return .favoriteAdd
        case .remove:
            return .favoriteRemove
        }
    }
    
    fileprivate var subscriptionName: AnalyticsHiddenEventName {
        switch self {
        case .add:
            return .subscriptionAdd
        case .remove:
            return .subscriptionRemove
        }
    }
    
    fileprivate var watchLaterName: AnalyticsHiddenEventName {
        switch self {
        case .add:
            return .watchLaterAdd
        case .remove:
            return .watchLaterRemove
        }
    }
}

@objc enum AnalyticsContiniousPlaybackAction: UInt {
    case display
    case playAutomatic
    case play
    case cancel
    
    fileprivate var source: AnalyticsEventSource {
        switch self {
        case .display, .playAutomatic:
            return .automatic
        case .play, .cancel:
            return .button
        }
    }
    
    fileprivate var type: AnalyticsEventType {
        switch self {
        case .display:
            return .display
        case .playAutomatic, .play:
            return .playMedia
        case .cancel:
            return .cancel
        }
    }
}

@objc enum AnalyticsNotificationAction: UInt {
    case playMedia
    case displayShow
    case alert
    
    fileprivate var type: AnalyticsEventType {
        switch self {
        case .playMedia:
            return .playMedia
        case .displayShow:
            return .displayShow
        case .alert:
            return .notificationAlert
        }
    }
}

@objc enum AnalyticsOpenUrlAction: UInt {
    case openPlayApp
    case playMedia
    case displayShow
    case displayPage
    case displayUrl
    
    fileprivate var type: AnalyticsEventType {
        switch self {
        case .openPlayApp:
            return .openPlayApp
        case .playMedia:
            return .playMedia
        case .displayShow:
            return .displayShow
        case .displayPage:
            return .displayPage
        case .displayUrl:
            return .displayURL
        }
    }
}
            
@objc enum AnalyticsIdentityAction: UInt {
    case displayLogin
    case cancelLogin
    case login
    case logout
    case unexpectedLogout
    
    fileprivate var labels: SRGAnalyticsHiddenEventLabels {
        let labels = SRGAnalyticsHiddenEventLabels()
        switch self {
        case .displayLogin:
            labels.type = AnalyticsEventType.displayLogin.rawValue
        case .cancelLogin:
            labels.source = AnalyticsEventSource.button.value
            labels.type = AnalyticsEventType.cancelLogin.rawValue
        case .login:
            labels.source = AnalyticsEventSource.button.value
            labels.type = AnalyticsEventType.login.rawValue
        case .logout:
            labels.source = AnalyticsEventSource.button.value
            labels.type = AnalyticsEventType.logout.rawValue
        case .unexpectedLogout:
            labels.source = AnalyticsEventSource.automatic.value
            labels.type = AnalyticsEventType.logout.rawValue
        }
        return labels
    }
}

@objc enum AnalyticsNotificationFrom: UInt {
    case application
    case operatingSystem
    
    fileprivate var name: AnalyticsHiddenEventName {
        switch self {
        case .application:
            return .notificationOpen
        case .operatingSystem:
            return .pushNotificationOpen
        }
    }
    
    fileprivate var source: AnalyticsEventSource {
        switch self {
        case .application:
            return .notification
        case .operatingSystem:
            return .notificationPush
        }
    }
}

@objc enum AnalyticsSharingAction: UInt {
    case media
    case show
    case section
    
    fileprivate var name: AnalyticsHiddenEventName {
        switch self {
        case .media:
            return .mediaShare
        case .show:
            return .showShare
        case .section:
            return .sectionShare
        }
    }
}

@objc enum AnalyticsSharedMediaType: UInt {
    case none
    case content
    case contentAtTime
    case currentClip
    
    fileprivate var value: String? {
        switch self {
        case .content:
            return "content"
        case .contentAtTime:
            return "content_at_time"
        case .currentClip:
            return "current_clip"
        default:
            return nil
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
            return "openfavorites"
        case .downloads:
            return "opendownloads"
        case .history:
            return "openhistory"
        case .search:
            return "opensearch"
        }
    }
}

@objc enum AnalyticsUserActivityAction: UInt {
    case playMedia
    case displayShow
    
    fileprivate var type: AnalyticsEventType {
        switch self {
        case .playMedia:
            return .playMedia
        case .displayShow:
            return .displayShow
        }
    }
}

@objc enum AnalyticsEventSource: UInt {
    case button
    
    case contextMenu
    
    case automatic
    case close
        
    case customURL
    case universalLink
    
    case notification
    case notificationPush
    
    case selection
    case swipe
    
    fileprivate var value: String {
        switch self {
        case .button:
            return "button"
        case .contextMenu:
            return "context_menu"
        case .automatic:
            return "automatic"
        case .close:
            return "close"
        case .customURL:
            return "scheme_url"
        case .universalLink:
            return "deep_link"
        case .notification:
            return "notification"
        case .notificationPush:
            return "push_notification"
        case .selection:
            return "selection"
        case .swipe:
            return "swipe"
        }
    }
}

private enum AnalyticsHiddenEventName: String {
    case calendarAdd = "calendar_add"
    
    case continuousPlayback = "continuous_playback"
    
    case downloadAdd = "download_add"
    case downloadRemove = "download_remove"
    
    case favoriteAdd = "favorite_add"
    case favoriteRemove = "favorite_remove"
    
    case googleCast = "google_cast"
    
    case historyRemove = "history_remove"
    
    case identity = "identity"
    
    case mediaShare = "media_share"
    case sectionShare = "section_share"
    case showShare = "show_share"
    
    case notificationOpen = "notification_open"
    case pushNotificationOpen = "push_notification_open"
    
    case openUrl = "open_url"
    
    case pictureInPicture = "picture_in_picture"
    
    case quickActions = "quick_actions"
    
    case subscriptionAdd = "subscription_add"
    case subscriptionRemove = "subscription_remove"
    
    case userActivityIos = "user_activity_ios"
    
    case watchLaterAdd = "watch_later_add"
    case watchLaterRemove = "watch_later_remove"
}

private enum AnalyticsEventType: String {
    case display = "display"
    case cancel = "cancel"
    
    case playMedia = "play_media"

    case displayShow = "display_show"
    case displayPage = "display_page"
    case displayURL = "display_url"
    
    case notificationAlert = "notification_alert"
    
    case displayLogin = "display_login"
    case cancelLogin = "cancel_login"
    case login = "login"
    case logout = "logout"
    
    case openPlayApp = "open_play_app"
}
