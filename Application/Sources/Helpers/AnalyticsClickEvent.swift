//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalytics
import SRGDataProvider

/**
 *  Play analytics click event.
 */
struct AnalyticsClickEvent {
    let name: String
    let labels: SRGAnalyticsHiddenEventLabels
    
    func send() {
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
    }
    
    init(name: String, value1: String? = nil, value2: String? = nil, value3: String? = nil, value4: String? = nil, value5: String? = nil) {
        self.name = name
        
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.source = "2797"
        labels.type = "ClickEvent"
        labels.extraValue1 = value1
        labels.extraValue2 = value2
        labels.extraValue3 = value3
        labels.extraValue4 = value4
        labels.extraValue5 = value5
        self.labels = labels
    }
    
    static func tvGuideOpenInfoBox(program: SRGProgram, programGuideLayout: ProgramGuideLayout) -> AnalyticsClickEvent {
        return Self(
            name: "TvGuideOpenInfoBox",
            value1: "tvGuide",
            value2: programGuideLayout == .grid ? "Grid" : "List",
            value3: program.title,
            value4: program.mediaURN
        )
    }
    
    static func TvGuidePlayLivestream(program: SRGProgram, channel: SRGChannel) -> AnalyticsClickEvent {
        return Self(
            name: "TvGuidePlayLivestream",
            value1: "tvGuide",
            value2: channel.title,
            value3: "InfoBox",
            value4: program.mediaURN
        )
    }
    
    static func TvGuidePlayMedia(media: SRGMedia, programIsLive: Bool, channel: SRGChannel) -> AnalyticsClickEvent {
        return Self(
            name: "TvGuidePlayMedia",
            value1: "tvGuide",
            value2: media.urn,
            value3: "InfoBox",
            value4: programIsLive ? channel.title : nil
        )
    }
    
    static func TvGuideNow() -> AnalyticsClickEvent {
        return Self(
            name: "DateSelectionNowClick",
            value1: "tvGuide"
        )
    }
    
    static func TvGuideTonight() -> AnalyticsClickEvent {
        return Self(
            name: "DateSelectionTonightClick",
            value1: "tvGuide"
        )
    }
    
    static func TvGuideChangeLayout(to programGuideLayout: ProgramGuideLayout) -> AnalyticsClickEvent {
        return Self(
            name: "TvGuideSwitchLayout",
            value1: "tvGuide",
            value2: programGuideLayout == .grid ? "Grid" : "List"
        )
    }
}