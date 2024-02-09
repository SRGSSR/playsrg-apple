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
    
    private enum DateStyle {
        case date
        case shortDate
        case shortDateAndTime
    }
    
    private static func formattedDate(for media: SRGMedia, style: DateStyle = .date) -> String? {
        if media.play_isWebFirst {
            return NSLocalizedString("In advance", comment: "Short text replacing date for a web first content.")
        }
        else if shouldDisplayPublication(for: media) {
            switch style {
            case .date:
                return DateFormatter.play_relativeDate.string(from: media.date).capitalizedFirstLetter
            case .shortDate:
                return DateFormatter.play_relativeShortDate.string(from: media.date)
            case .shortDateAndTime:
                return DateFormatter.play_shortDateAndTime.string(from: media.date)
            }
        }
        else {
            return nil
        }
    }
    
    private static func formattedTime(for media: SRGMedia) -> String {
        return DateFormatter.play_time.string(from: media.date)
    }
    
    private static func areRedundant(media: SRGMedia, show: SRGShow) -> Bool {
        return media.title.lowercased() == show.title.lowercased()
    }
    
    static func title(for media: SRGMedia, style: Style) -> String? {
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
                else if let publicationDate = formattedDate(for: media, style: .shortDate) {
                    // Unbreakable spaces before / after the separator
                    return "\(show.title) · \(publicationDate)"
                }
                else {
                    return show.title
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
        return media.play_summary?.compacted
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
    
    private static func shouldDisplayPublication(for media: SRGMedia) -> Bool {
        let now = Date()
        return media.timeAvailability(at: now) != .notYetAvailable
        && media.contentType != .livestream
        && !(media.contentType == .scheduledLivestream && media.timeAvailability(at: now) == .available)
    }
    
    private static func publication(for media: SRGMedia) -> String? {
        return formattedDate(for: media, style: .shortDateAndTime)
    }
    
    private static func expiration(for media: SRGMedia) -> String? {
        guard let endDate = media.endDate else { return nil }
        return String(format: NSLocalizedString("Available until %@", comment: "Availability until date, specified as parameter"), DateFormatter.play_shortDate.string(from: endDate))
    }
    
    static func availability(for media: SRGMedia) -> String {
        var values: [String] = []
        
        if let publication = publication(for: media) {
            values.append(publication)
        }
        
        if shouldDisplayExpiration(for: media), let expiration = expiration(for: media) {
            values.append(expiration)
        }
        
        // Unbreakable spaces before / after the separator
        return values.joined(separator: " · ")
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
    
    static func liveBadgeProperties() -> BadgeProperties {
        return BadgeProperties(
            text: NSLocalizedString("Live", comment: "Short label identifying a livestream. Display in uppercase.").uppercased(),
            color: .srgLightRed
        )
    }
    
    static func availabilityBadgeProperties(for media: SRGMedia) -> BadgeProperties? {
        if media.contentType == .livestream {
            return liveBadgeProperties()
        }
        else {
            let now = Date()
            let availability = media.timeAvailability(at: now)
            switch availability {
            case .notYetAvailable:
                let startDate = media.startDate ?? media.date
                return BadgeProperties(
                    text: DateFormatter.play_relativeShortDateAndTime.string(from: startDate).capitalizedFirstLetter,
                    color: .play_black80a
                )
            case .notAvailableAnymore:
                return BadgeProperties(
                    text: NSLocalizedString("Expired", comment: "Short label identifying content which has expired."),
                    color: .srgGray96
                )
            case .available:
                if media.contentType == .scheduledLivestream {
                    return BadgeProperties(
                        text: NSLocalizedString("Live", comment: "Short label identifying a livestream. Display in uppercase.").uppercased(),
                        color: .srgLightRed
                    )
                }
                else if media.play_isWebFirst && ApplicationConfiguration.shared.isWebFirstBadgeEnabled {
                    return BadgeProperties(
                        text: NSLocalizedString("Web first", comment: "Short label identifying a web first content."),
                        color: .srgDarkRed
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
