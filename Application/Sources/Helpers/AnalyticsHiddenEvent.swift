//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalytics
import SRGDataProvider

/**
 *  Play analytics hidden event.
 */
struct AnalyticsHiddenEvent {
    let name: String
    let labels: SRGAnalyticsHiddenEventLabels
    
    func send() {
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
    }
    
    static func calendarAdd(channel: SRGChannel) -> AnalyticsHiddenEvent {
        return Self(
            name: "calendar_add",
            source: AnalyticsSource.button.rawValue,
            value: channel.urn,
            value1: channel.title
        )
    }
    
    static func continuousPlayback(source: AnalyticsSource, type: AnalyticsType, mediaUrn: String, recommendationUid: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: "continuous_playback",
            source: source.rawValue,
            type: type.rawValue,
            value: mediaUrn,
            value1: recommendationUid
        )
    }
    
    static func download(actionType: AnalyticsHiddenEventActionType, source: AnalyticsSource, urn: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: actionType.downloadName,
            source: source.rawValue,
            value: urn
        )
    }
    
    static func favorite(actionType: AnalyticsHiddenEventActionType, source: AnalyticsSource, urn: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: actionType.favoriteName,
            source: source.rawValue,
            value: urn
        )
    }
    
    static func history(actionType: AnalyticsHiddenEventActionType, source: AnalyticsSource, urn: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: actionType.historyName,
            source: source.rawValue,
            value: urn
        )
    }
    
    static func identity(action: AnalyticsHiddenEventIdentityAction) -> AnalyticsHiddenEvent {
        return Self(
            name: "identity",
            labels: action.labels
        )
    }
    
    static func openUrl(labels: SRGAnalyticsHiddenEventLabels) -> AnalyticsHiddenEvent {
        return Self(
            name: "open_url",
            labels: labels
        )
    }
    
    static func pictureInPicture(urn: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: "picture_in_picture",
            value: urn
        )
    }
    
    static func shortcutItem(type: AnalyticsType) -> AnalyticsHiddenEvent {
        return Self(
            name: "quick_actions",
            type: type.rawValue
        )
    }
    
    static func subscription(actionType: AnalyticsHiddenEventActionType, source: AnalyticsSource, urn: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: actionType.subscriptionName,
            source: source.rawValue,
            value: urn
        )
    }
    
    static func userActivity(type: AnalyticsType, urn: String) -> AnalyticsHiddenEvent {
        return Self(
            name: "user_activity_ios",
            source: "handoff",
            type: type.rawValue,
            value: urn
        )
    }
    
    static func watchLater(actionType: AnalyticsHiddenEventActionType, source: AnalyticsSource, urn: String?) -> AnalyticsHiddenEvent {
        return Self(
            name: actionType.watchLaterName,
            source: source.rawValue,
            value: urn
        )
    }
    
    private init(name: String, source: String? = nil, type: String? = nil, value: String? = nil, value1: String? = nil, value2: String? = nil, value3: String? = nil, value4: String? = nil, value5: String? = nil) {
        self.name = name
        
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
    
    private init(name: String, labels: SRGAnalyticsHiddenEventLabels) {
        self.name = name
        self.labels = labels
    }
}

/**
 *  Objective-C Play analytics hidden events compatibility.
 */
@objc class AnalyticsHiddenEvents: NSObject {
    let event: AnalyticsHiddenEvent
    
    @objc func send() {
        self.event.send()
    }
    
    @objc class func continuousPlayback(source: AnalyticsSource, type: AnalyticsType, mediaUrn: String, recommendationUid: String?) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.continuousPlayback(source: source, type: type, mediaUrn: mediaUrn, recommendationUid: recommendationUid))
    }
    
    @objc class func download(actionType: AnalyticsHiddenEventActionType, source: AnalyticsSource, urn: String?) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.download(actionType: actionType, source: source, urn: urn))
    }
    
    @objc class func favorite(actionType: AnalyticsHiddenEventActionType, source: AnalyticsSource, urn: String?) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.favorite(actionType: actionType, source: source, urn: urn))
    }
    
    @objc class func identity(action: AnalyticsHiddenEventIdentityAction) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.identity(action: action))
    }
    
    @objc class func openUrl(labels: SRGAnalyticsHiddenEventLabels) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.openUrl(labels: labels))
    }
    
    @objc class func pictureInPicture(urn: String?) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.pictureInPicture(urn: urn))
    }
    
    @objc class func shortcutItem(type: AnalyticsType) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.shortcutItem(type: type))
    }
    
    @objc class func userActivity(type: AnalyticsType, urn: String) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.userActivity(type: type, urn: urn))
    }
    
    @objc class func watchLater(actionType: AnalyticsHiddenEventActionType, source: AnalyticsSource, urn: String?) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.watchLater(actionType: actionType, source: source, urn: urn))
    }
    
    required init(event: AnalyticsHiddenEvent) {
        self.event = event
    }
}

@objc enum AnalyticsHiddenEventActionType: UInt {
    case add
    case remove
    
    var downloadName: String {
        switch self {
        case .add:
            return "download_add"
        case .remove:
            return "download_remove"
        }
    }
    
    var favoriteName: String {
        switch self {
        case .add:
            return "favorite_add"
        case .remove:
            return "favorite_remove"
        }
    }
    
    var historyName: String {
        switch self {
        case .add:
            return "history_add"
        case .remove:
            return "history_remove"
        }
    }
    
    var subscriptionName: String {
        switch self {
        case .add:
            return "subscription_add"
        case .remove:
            return "subscription_remove"
        }
    }
    
    var watchLaterName: String {
        switch self {
        case .add:
            return "watch_later_add"
        case .remove:
            return "watch_later_remove"
        }
    }
}

@objc enum AnalyticsHiddenEventIdentityAction: UInt {
    case displayLogin
    case cancelLogin
    case login
    case logout
    case unexpectedLogout
    
    var labels: SRGAnalyticsHiddenEventLabels {
        let labels = SRGAnalyticsHiddenEventLabels()
        switch self {
        case .displayLogin:
            labels.type = AnalyticsType.actionDisplayLogin.rawValue
        case .cancelLogin:
            labels.source = AnalyticsSource.button.rawValue
            labels.type = AnalyticsType.actionCancelLogin.rawValue
        case .login:
            labels.source = AnalyticsSource.button.rawValue
            labels.type = AnalyticsType.actionLogin.rawValue
        case .logout:
            labels.source = AnalyticsSource.button.rawValue
            labels.type = AnalyticsType.actionLogout.rawValue
        case .unexpectedLogout:
            labels.source = AnalyticsSource.automatic.rawValue
            labels.type = AnalyticsType.actionLogout.rawValue
        }
        return labels
    }
}
