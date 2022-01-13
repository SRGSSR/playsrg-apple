//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift

struct MediaDescription {
    enum Style {
        /// Show information emphasis
        case show
        /// Date information emphasis
        case date
        /// Time information emphasis
        case time
    }
    
    private enum FormattedDurationStyle {
        /// Full duration format
        case full
        /// Short duration format
        case short
    }
    
    struct BadgeProperties {
        let text: String
        let color: UIColor
    }
    
    private static func formattedDuration(from: Date, to: Date, format: FormattedDurationStyle = .full) -> String? {
        guard let days = Calendar.current.dateComponents([.day], from: from, to: to).day else { return nil }
        
        if format == .short {
            switch days {
            case 0:
                return PlayShortFormattedHours(to.timeIntervalSince(from))
            case 1...3:
                return PlayShortFormattedDays(to.timeIntervalSince(from))
            default:
                return nil
            }
        }
        else {
            switch days {
            case 0:
                // Minimum displayed is 1 hour
                return PlayFormattedHours(max(to.timeIntervalSince(from), 60 * 60))
            case 1...30:
                return PlayFormattedDays(to.timeIntervalSince(from))
            default:
                return nil
            }
        }
    }
    
    private static func formattedDate(for media: SRGMedia) -> String {
        return DateFormatter.play_relative.string(from: media.date).capitalizedFirstLetter
    }
    
    private static func formattedTime(for media: SRGMedia) -> String {
        return DateFormatter.play_time.string(from: media.date).capitalizedFirstLetter
    }
    
    private static func areRedundant(media: SRGMedia, show: SRGShow) -> Bool {
        return media.title.lowercased() == show.title.lowercased()
    }
    
    static func title(for media: SRGMedia, style: Style) -> String {
        switch style {
        case .show:
            if let show = media.show, areRedundant(media: media, show: show) {
                return formattedDate(for: media)
            }
            else {
                return media.title
            }
        case .date, .time:
            return media.title
        }
    }
    
    static func subtitle(for media: SRGMedia, style: Style) -> String? {
        guard media.contentType != .livestream else { return nil }
        
        switch style {
        case .show:
            if let show = media.show {
                if areRedundant(media: media, show: show) {
                    return show.title
                }
                else {
                    // Unbreakable spaces before / after the separator
                    return "\(show.title) · \(DateFormatter.play_relativeShort.string(from: media.date))"
                }
            }
            else {
                return formattedDate(for: media)
            }
        case .date:
            return formattedDate(for: media)
        case .time:
            return formattedTime(for: media)
        }
    }
    
    static func summary(for media: SRGMedia) -> String? {
        return media.summary
    }
    
    static func duration(for media: SRGMedia) -> Double? {
        guard media.contentType != .livestream && media.contentType != .scheduledLivestream else { return nil }
        return media.duration / 1000
    }
    
    static func availability(for media: SRGMedia) -> String? {
        let now = Date()
        switch media.timeAvailability(at: now) {
        case .notAvailableAnymore:
            let endDate = (media.endDate != nil) ? media.endDate! : media.date.addingTimeInterval(media.duration / 1000)
            guard let expiringDays = Self.formattedDuration(from: now, to: endDate) else { return nil }
            return String(format: NSLocalizedString("Not available since %@", comment: "Explains that a content has expired (days or hours ago). Displayed in the media player view."), expiringDays)
        case .available:
            guard let endDate = media.endDate, media.contentType != .livestream, media.contentType != .scheduledLivestream, media.contentType != .trailer else { return nil }
            guard let remainingDays = Self.formattedDuration(from: now, to: endDate) else { return nil }
            return String(format: NSLocalizedString("Still available for %@", comment: "Explains that a content is still online (for days or hours) but will expire. Displayed in the media player view."), remainingDays)
        default:
            return nil
        }
    }
    
    static func accessibilityLabel(for media: SRGMedia) -> String? {
        if let show = media.show, !areRedundant(media: media, show: show) {
            return show.title.appending(", \(media.title)")
        }
        else {
            return media.title
        }
    }
    
    static func availabilityBadgeProperties(for media: SRGMedia) -> BadgeProperties? {
        if media.contentType == .livestream {
            return BadgeProperties(
                text: NSLocalizedString("Live", comment: "Short label identifying a livestream. Display in uppercase."),
                color: .srgLightRed
            )
        }
        else {
            let now = Date()
            let availability = media.timeAvailability(at: now)
            switch availability {
            case .notYetAvailable:
                return BadgeProperties(
                    text: NSLocalizedString("Soon", comment: "Short label identifying content which will be available soon."),
                    color: .play_green
                )
            case .notAvailableAnymore:
                return BadgeProperties(
                    text: NSLocalizedString("Expired", comment: "Short label identifying content which has expired."),
                    color: .srgGray96
                )
            case .available:
                if media.contentType == .scheduledLivestream {
                    return BadgeProperties(
                        text: NSLocalizedString("Live", comment: "Short label identifying a livestream. Display in uppercase."),
                        color: .srgLightRed
                    )
                }
                else if media.play_isWebFirst {
                    return BadgeProperties(
                        text: NSLocalizedString("Web first", comment: "Web first label on media cells"),
                        color: .srgBlue
                    )
                }
                else if let endDate = media.endDate, media.contentType == .episode || media.contentType == .clip,
                            let remainingTime = Self.formattedDuration(from: now, to: endDate, format: .short) {
                    return BadgeProperties(
                        text: String(format: NSLocalizedString("%@ left", comment: "Short label displayed on a media expiring soon"), remainingTime),
                        color: .play_orange
                    )
                }
                else {
                    return nil
                }
            default:
                return nil
            }
        }
    }
}
