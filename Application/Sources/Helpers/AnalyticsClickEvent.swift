//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalytics
import SRGDataProviderModel

/**
 *  Play analytics click event. Defined for native and web Play applications.
 */
struct AnalyticsClickEvent {
    let name: String
    let labels: SRGAnalyticsEventLabels

    private enum PageId: String {
        case tvGuide
    }

    /**
     *  Each struct created have expected values.
     *  Use this method to send the event when needed.
     */
    func send() {
        SRGAnalyticsTracker.shared.trackEvent(withName: name, labels: labels)
    }

    static func tvGuideOpenInfoBox(program: SRGProgram, programGuideLayout: ProgramGuideLayout) -> Self {
        Self(
            name: "TvGuideOpenInfoBox",
            value1: PageId.tvGuide.rawValue,
            value2: programGuideLayout == .grid ? "Grid" : "List",
            value3: program.title,
            value4: program.mediaURN
        )
    }

    enum TvGuidePlaySource: String {
        case infoBox = "InfoBox"
        case grid = "Grid"
    }

    static func tvGuidePlayLivestream(program: SRGProgram, channel: SRGChannel, source: TvGuidePlaySource = .infoBox) -> Self {
        Self(
            name: "TvGuidePlayLivestream",
            value1: PageId.tvGuide.rawValue,
            value2: channel.title,
            value3: source.rawValue,
            value4: program.mediaURN
        )
    }

    static func tvGuidePlayMedia(media: SRGMedia, programIsLive: Bool, channel: SRGChannel, source: TvGuidePlaySource = .infoBox) -> Self {
        Self(
            name: "TvGuidePlayMedia",
            value1: PageId.tvGuide.rawValue,
            value2: media.urn,
            value3: source.rawValue,
            value4: programIsLive ? channel.title : nil
        )
    }

    static func tvGuideNow() -> Self {
        Self(
            name: "DateSelectionNowClick",
            value1: PageId.tvGuide.rawValue
        )
    }

    static func tvGuideTonight() -> Self {
        Self(
            name: "DateSelectionTonightClick",
            value1: PageId.tvGuide.rawValue
        )
    }

    static func tvGuidePreviousDay() -> Self {
        Self(
            name: "DateSelectionPreviousDayClick",
            value1: PageId.tvGuide.rawValue
        )
    }

    static func tvGuideNextDay() -> Self {
        Self(
            name: "DateSelectionNextDayClick",
            value1: PageId.tvGuide.rawValue
        )
    }

    static func tvGuideCalendar(to selectedDate: Date) -> Self {
        Self(
            name: "DateSelectionCalendarClick",
            value1: DateFormatter.play_iso8601CalendarDate.string(from: selectedDate),
            value2: PageId.tvGuide.rawValue
        )
    }

    static func tvGuideChangeLayout(to programGuideLayout: ProgramGuideLayout) -> Self {
        Self(
            name: "TvGuideSwitchLayout",
            value1: PageId.tvGuide.rawValue,
            value2: programGuideLayout == .grid ? "Grid" : "List"
        )
    }

    private init(name: String, value1: String? = nil, value2: String? = nil, value3: String? = nil, value4: String? = nil, value5: String? = nil) {
        self.name = name

        let labels = SRGAnalyticsEventLabels()
        labels.source = "2797"
        labels.type = "ClickEvent"
        labels.extraValue1 = value1
        labels.extraValue2 = value2
        labels.extraValue3 = value3
        labels.extraValue4 = value4
        labels.extraValue5 = value5
        self.labels = labels
    }
}
