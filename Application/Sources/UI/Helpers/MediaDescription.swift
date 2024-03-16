//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift

@objc class MediaDescription: NSObject {
    override init() {
        fatalError("init() is not available")
    }

    // MARK: - Title and subtitle

    enum Style {
        /// Show information emphasis
        case show
        /// Date information emphasis
        case date
        /// Time information emphasis
        case time
    }

    static func title(for media: SRGMedia, style: Style) -> String? {
        switch style {
        case .show:
            if let show = media.show, areRedundant(media: media, show: show) {
                formattedDate(for: media)
            } else {
                media.title
            }
        case .date, .time:
            media.title
        }
    }

    static func subtitle(for media: SRGMedia, style: Style) -> String? {
        guard media.contentType != .livestream else { return nil }

        switch style {
        case .show:
            if let show = media.show {
                if areRedundant(media: media, show: show) {
                    return show.title
                } else if let formattedDate = formattedDate(for: media, style: .shortDate) {
                    // Unbreakable spaces before / after the separator
                    return "\(show.title) · \(formattedDate)"
                } else {
                    return show.title
                }
            } else {
                return formattedDate(for: media)
            }
        case .date:
            return formattedDate(for: media)
        case .time:
            if let show = media.show, !areRedundant(media: media, show: show) {
                // Unbreakable spaces before / after the separator
                return "\(formattedTime(for: media)) · \(show.title)"
            }
            else {
                return formattedTime(for: media)
            }
        }
    }

    static func summary(for media: SRGMedia) -> String? {
        media.play_summary?.compacted
    }

    static func duration(for media: SRGMedia) -> Double? {
        guard media.contentType != .livestream, media.contentType != .scheduledLivestream else { return nil }
        return media.duration / 1000
    }

    @objc static func availability(for media: SRGMedia?) -> String {
        guard let media else { return "" }

        var values: [String] = []

        if let date = formattedDate(for: media, style: .shortDateAndTime) {
            values.append(date)
        }

        if let expirationDate = formattedExpirationDate(for: media) {
            values.append(expirationDate)
        }

        // Unbreakable spaces before / after the separator
        return values.joined(separator: " · ")
    }

    // MARK: - Accessibility

    static func cellAccessibilityLabel(for media: SRGMedia) -> String? {
        let accessibilityLabel: String = if let show = media.show, !areRedundant(media: media, show: show) {
            show.title.appending(", \(media.title)")
        } else {
            media.title
        }

        if let youthProtectionLabel = SRGAccessibilityLabelForYouthProtectionColor(media.youthProtectionColor) {
            return accessibilityLabel.appending(", \(youthProtectionLabel)")
        } else {
            return accessibilityLabel
        }
    }

    @objc static func availabilityAccessibilityLabel(for media: SRGMedia?) -> String? {
        guard let media else { return nil }

        var values: [String] = []

        if let date = formattedDate(for: media, style: .shortDateAndTime, accessibilityLabel: true) {
            values.append(date)
        }

        if let expirationDate = formattedExpirationDate(for: media, accessibilityLabel: true) {
            values.append(expirationDate)
        }

        // Unbreakable spaces before / after the separator
        return values.joined(separator: " · ")
    }

    // MARK: - Badges

    struct BadgeProperties {
        let text: String
        let color: UIColor
    }

    static func liveBadgeProperties() -> BadgeProperties {
        BadgeProperties(
            text: NSLocalizedString("Live", comment: "Short label identifying a livestream. Display in uppercase.").uppercased(),
            color: .srgLightRed
        )
    }

    static func availabilityBadgeProperties(for media: SRGMedia) -> BadgeProperties? {
        if media.contentType == .livestream {
            return liveBadgeProperties()
        } else {
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
                    return liveBadgeProperties()
                } else if media.play_isWebFirst && ApplicationConfiguration.shared.isWebFirstBadgeEnabled {
                    return BadgeProperties(
                        text: NSLocalizedString("Web first", comment: "Short label identifying a web first content."),
                        color: .srgDarkRed
                    )
                } else if let endDate = media.endDate, media.contentType == .episode || media.contentType == .clip,
                          let remainingTime = Self.formattedDuration(from: now, to: endDate) {
                    return BadgeProperties(
                        text: String(format: NSLocalizedString("%@ left", comment: "Short label displayed on a media expiring soon"), remainingTime),
                        color: .play_orange
                    )
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
    }

    // MARK: - Private methods

    private static func formattedDuration(from: Date, to: Date) -> String? {
        let components = Calendar.current.dateComponents([.day, .minute], from: from, to: to)
        switch components.day! {
        case 0:
            switch components.minute! {
            case 0 ..< 60:
                return PlayFormattedMinutes(to.timeIntervalSince(from))
            default:
                return PlayFormattedHours(to.timeIntervalSince(from))
            }
        case 1 ... 3:
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

    private static func formattedDate(for media: SRGMedia, style: DateStyle = .date, accessibilityLabel: Bool = false) -> String? {
        if media.play_isWebFirst {
            NSLocalizedString("In advance", comment: "Short text replacing date for a web first content.")
        } else if shouldDisplayDate(for: media) {
            switch style {
            case .date:
                if accessibilityLabel {
                    PlayAccessibilityRelativeDateFromDate(media.date)
                } else {
                    DateFormatter.play_relativeDate.string(from: media.date).capitalizedFirstLetter
                }
            case .shortDate:
                if accessibilityLabel {
                    PlayAccessibilityRelativeDateFromDate(media.date)
                } else {
                    DateFormatter.play_relativeShortDate.string(from: media.date)
                }
            case .shortDateAndTime:
                if accessibilityLabel {
                    PlayAccessibilityDateAndTimeFromDate(media.date)
                } else {
                    DateFormatter.play_shortDateAndTime.string(from: media.date)
                }
            }
        } else {
            nil
        }
    }

    private static func formattedExpirationDate(for media: SRGMedia, accessibilityLabel: Bool = false) -> String? {
        guard let endDate = media.endDate, shouldDisplayExpirationDate(for: media) else { return nil }
        let dateString = accessibilityLabel
            ? PlayAccessibilityDateFromDate(endDate)
            : DateFormatter.play_shortDate.string(from: endDate)
        return String(format: NSLocalizedString("Available until %@", comment: "Availability until date, specified as parameter"), dateString)
    }

    private static func formattedTime(for media: SRGMedia) -> String {
        DateFormatter.play_time.string(from: media.date)
    }

    private static func areRedundant(media: SRGMedia, show: SRGShow) -> Bool {
        media.title.lowercased() == show.title.lowercased()
    }

    private static func shouldDisplayExpirationDate(for media: SRGMedia) -> Bool {
        let now = Date()
        guard media.timeAvailability(at: now) == .available,
              media.contentType != .scheduledLivestream, media.contentType != .trailer,
              let endDate = media.endDate, media.contentType != .livestream else { return false }
        let remainingDateComponents = Calendar.current.dateComponents([.day], from: now, to: endDate)
        return remainingDateComponents.day! > 3
    }

    private static func shouldDisplayDate(for media: SRGMedia) -> Bool {
        let now = Date()
        return media.timeAvailability(at: now) != .notYetAvailable
            && media.contentType != .livestream
            && !(media.contentType == .scheduledLivestream && media.timeAvailability(at: now) == .available)
    }
}
