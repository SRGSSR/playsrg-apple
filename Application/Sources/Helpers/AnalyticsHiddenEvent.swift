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
    
    static func shortcutItem(type: AnalyticsType) -> AnalyticsHiddenEvent {
        return Self(
            name: "quick_actions",
            type: type.rawValue
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
    
    @objc class func shortcutItem(type: AnalyticsType) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.shortcutItem(type: type))
    }
    
    @objc class func userActivity(type: AnalyticsType, urn: String) -> AnalyticsHiddenEvents {
        return Self(event: AnalyticsHiddenEvent.userActivity(type: type, urn: urn))
    }
    
    required init(event: AnalyticsHiddenEvent) {
        self.event = event
    }
}
