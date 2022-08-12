//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift

enum MediaDescription {
    enum Style {
        /// Show information emphasis
        case show
        /// Date information emphasis
        case date
        /// Time information emphasis
        case time
    }
    
    struct BadgeProperties {
        let text: String
        let color: UIColor
    }
    
    private static func formattedDuration(from: Date, to: Date) -> String? {
        let components = Calendar.current.dateComponents([.day, .minute], from: from, to: to)
        switch components.day! {
        case 0:
            switch components.minute! {
            case 0..<60:
                return PlayFormattedMinutes(to.timeIntervalSince(from))
            default:
                return PlayFormattedHours(to.timeIntervalSince(from))
            }
        case 1...3:
            return PlayFormattedDays(to.timeIntervalSince(from))
        default:
            return nil
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
    
    private static func shouldDisplayExpiration(for media: SRGMedia) -> Bool {
        let now = Date()
        guard media.timeAvailability(at: now) == .available,
              media.contentType != .scheduledLivestream, media.contentType != .trailer,
              let endDate = media.endDate, media.contentType != .livestream else { return false }
        let remainingDateComponents = Calendar.current.dateComponents([.day], from: now, to: endDate)
        return remainingDateComponents.day! > 3
    }
    
    private static func publication(for media: SRGMedia) -> String {
        return DateFormatter.play_shortDateAndTime.string(from: media.date)
    }
    
    private static func expiration(for media: SRGMedia) -> String? {
        guard let endDate = media.endDate else { return nil }
        return String(format: NSLocalizedString("Available until %@", comment: "Availability until date, specified as parameter"), DateFormatter.play_short.string(from: endDate))
    }
    
    static func availability(for media: SRGMedia) -> String {
        let publication = publication(for: media)
        if shouldDisplayExpiration(for: media), let expiration = expiration(for: media) {
            // Unbreakable spaces before / after the separator
            return "\(publication) - \(expiration)"
        }
        else {
            return publication
        }
    }
    
    static func accessibilityLabel(for media: SRGMedia) -> String? {
        let accessibilityLabel: String
        if let show = media.show, !areRedundant(media: media, show: show) {
            accessibilityLabel = show.title.appending(", \(media.title)")
        }
        else {
            accessibilityLabel = media.title
        }
        
        if let youthProtectionLabel = SRGAccessibilityLabelForYouthProtectionColor(media.youthProtectionColor) {
            return accessibilityLabel.appending(", \(youthProtectionLabel)")
        }
        else {
            return accessibilityLabel
        }
    }
    
    static func availabilityBadgeProperties(for media: SRGMedia, allowsDateDisplay: Bool = true) -> BadgeProperties? {
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
                if allowsDateDisplay, let startDate = media.startDate {
                    return BadgeProperties(
                        text: DateFormatter.play_relativeShortDateAndTime.string(from: startDate),
                        color: .play_green
                    )
                }
                else {
                    return BadgeProperties(
                        text: NSLocalizedString("Soon", comment: "Short label identifying content which will be available soon."),
                        color: .play_green
                    )
                }
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
                        text: NSLocalizedString("Web first", comment: "Short label identifying a web first content."),
                        color: .srgBlue
                    )
                }
                else if let endDate = media.endDate, media.contentType == .episode || media.contentType == .clip,
                        let remainingTime = Self.formattedDuration(from: now, to: endDate) {
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
