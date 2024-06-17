//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import SRGDataProviderModel

// TODO: A value type similar to `SRGMediaSearchSettings` so that changes are automatically
//       published, which is not the case with a reference type like `SRGMediaSearchSettings`.
//       Remove when `SRGMediaSearchSettings` is a proper Swift value type.
struct MediaSearchSettings: Equatable {
    enum Duration {
        case any
        case lessThanFiveMinutes
        case moreThanThirtyMinutes
    }

    enum Period {
        case anytime
        case today
        case yesterday
        case thisWeek
        case lastWeek
    }

    var aggregationsEnabled = true
    var suggestionsEnabled = false
    var showUrns = Set<String>()
    var topicUrns = Set<String>()
    var mediaType: SRGMediaType = .none
    var subtitlesAvailable = false
    var downloadAvailable = false
    var playableAbroad = false
    var duration: Duration = .any
    var period: Period = .anytime
    var sortCriterium: SRGSortCriterium = .default
}

extension MediaSearchSettings {
    func applyDuration(to settings: SRGMediaSearchSettings) {
        switch duration {
        case .any:
            settings.minimumDurationInMinutes = nil
            settings.maximumDurationInMinutes = nil
        case .lessThanFiveMinutes:
            settings.minimumDurationInMinutes = nil
            settings.maximumDurationInMinutes = 5
        case .moreThanThirtyMinutes:
            settings.minimumDurationInMinutes = 30
            settings.maximumDurationInMinutes = nil
        }
    }

    func applyPeriod(to settings: SRGMediaSearchSettings) {
        switch period {
        case .anytime:
            settings.fromDay = nil
            settings.toDay = nil
        case .today:
            let today = SRGDay.today
            settings.fromDay = today
            settings.toDay = today
        case .yesterday:
            let yesterday = SRGDay(byAddingDays: -1, months: 0, years: 0, to: .today)
            settings.fromDay = yesterday
            settings.toDay = yesterday
        case .thisWeek:
            let firstDayOfThisWeek = SRGDay.start(for: .weekOfYear, containing: .today)
            settings.fromDay = firstDayOfThisWeek
            settings.toDay = SRGDay(byAddingDays: 6, months: 0, years: 0, to: firstDayOfThisWeek)
        case .lastWeek:
            let firstDayOfThisWeek = SRGDay.start(for: .weekOfYear, containing: .today)
            let firstDayOfLastWeek = SRGDay(byAddingDays: -6, months: 0, years: 0, to: firstDayOfThisWeek)
            settings.fromDay = firstDayOfLastWeek
            settings.toDay = SRGDay(byAddingDays: 6, months: 0, years: 0, to: firstDayOfLastWeek)
        }
    }

    var requestSettings: SRGMediaSearchSettings {
        let settings = SRGMediaSearchSettings()
        settings.aggregationsEnabled = aggregationsEnabled
        settings.suggestionsEnabled = suggestionsEnabled
        settings.showURNs = showUrns
        settings.topicURNs = topicUrns
        settings.mediaType = mediaType
        settings.subtitlesAvailable = subtitlesAvailable
        settings.downloadAvailable = downloadAvailable
        settings.playableAbroad = playableAbroad
        applyDuration(to: settings)
        applyPeriod(to: settings)
        settings.sortCriterium = sortCriterium
        return settings
    }
}
