//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct MediaDescription {
    private static func placeholder(length: Int) -> String {
        return String(repeating: " ", count: length)
    }
    
    private static func formattedDuration(from: Date, to: Date) -> String? {
        guard let days = Calendar.current.dateComponents([.day], from: from, to: to).day else { return nil }
        switch days {
        case 0:
            return DurationFormatters.shortHours(for: to.timeIntervalSince(from))
        case 1...30:
            return DurationFormatters.shortDays(for: to.timeIntervalSince(from))
        default:
            return nil
        }
    }
    
    static func title(for media: SRGMedia?) -> String {
        guard let media = media else { return placeholder(length: 20) }
        return media.show?.title ?? media.title
    }
    
    static func subtitle(for media: SRGMedia?) -> String {
        guard let media = media else { return placeholder(length: 25) }
        guard media.contentType != .livestream else { return "" }
        if let showTitle = media.show?.title, !media.title.contains(showTitle) {
            return media.title
        }
        else {
            return DateFormatters.formattedRelativeDateAndTime(for: media.date)
        }
    }
    
    static func summary(for media: SRGMedia?) -> String? {
        guard let media = media else { return placeholder(length: 160) }
        return media.summary
    }
    
    static func availability(for media: SRGMedia?) -> String? {
        guard let media = media else { return placeholder(length: 25) }
        let now = Date()
        let availability = media.timeAvailability(at: now)
        switch availability {
        case .notAvailableAnymore:
            let endDate = (media.endDate != nil) ? media.endDate! : media.date.addingTimeInterval(media.duration / 1000)
            guard let expiringDays = Self.formattedDuration(from: now, to: endDate) else { return nil }
            return NSLocalizedString("Not available since \(expiringDays)", comment:"Explains that a content has expired (days or hours ago). Displayed in the media player view.")
        case .available:
            guard let endDate = media.endDate, media.contentType != .livestream, media.contentType != .scheduledLivestream else { return nil }
            guard let remainingDays = Self.formattedDuration(from: now, to: endDate) else { return nil }
            return NSLocalizedString("Still available for \(remainingDays)", comment:"Explains that a content is still online (for days or hours) but will expire. Displayed in the media player view.")
        default:
            return nil
        }
    }
}
