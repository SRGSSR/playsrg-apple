//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct MediaDescription {
    enum Style {
        /// Show information emphasis
        case show
        /// Date information emphasis
        case date
    }
    
    private enum FormattedDurationStyle {
        /// Full duration format
        case full
        /// Short duration format
        case short
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
    
    static func title(for media: SRGMedia?, style: Style = .date) -> String? {
        guard let media = media else { return nil }
        
        switch style {
        case .show:
            return media.show?.title ?? media.title
        case .date:
            return media.title
        }
    }
    
    static func subtitle(for media: SRGMedia?, style: Style = .date) -> String? {
        guard let media = media else { return nil }
        guard media.contentType != .livestream else { return "" }
        
        switch style {
        case .show:
            if let showTitle = media.show?.title, media.title.lowercased() != showTitle.lowercased() {
                return media.title
            }
            else {
                return DateFormatter.play_relativeDateAndTime.string(from: media.date).capitalizedFirstLetter
            }
        case .date:
            return DateFormatter.play_relativeDateAndTime.string(from: media.date).capitalizedFirstLetter
        }
    }
    
    static func summary(for media: SRGMedia?) -> String? {
        guard let media = media else { return nil }
        return media.summary
    }
    
    static func duration(for media: SRGMedia?) -> String? {
        guard let media = media, media.contentType != .livestream && media.contentType != .scheduledLivestream else { return nil }
        return PlayShortFormattedMinutes(media.duration / 1000)
    }
    
    static func availability(for media: SRGMedia?) -> String? {
        guard let media = media else { return nil }
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
    
    static func accessibilityLabel(for media: SRGMedia?) -> String? {
        guard let media = media else { return nil }
        if let showTitle = media.show?.title, !media.title.lowercased().contains(showTitle.lowercased()) {
            return showTitle.appending(", \(media.title)")
        }
        else {
            return media.title
        }
    }
    
    static func availabilityBadgeProperties(for media: SRGMedia?) -> (text: String, color: Color)? {
        guard let media = media else { return nil }
        
        if media.contentType == .livestream {
            return (NSLocalizedString("Live", comment: "Short label identifying a livestream. Display in uppercase."), Color(.play_liveRed))
        }
        else {
            let now = Date()
            let availability = media.timeAvailability(at: now)
            switch availability {
            case .notYetAvailable:
                return (NSLocalizedString("Soon", comment: "Short label identifying content which will be available soon."), Color(.play_green))
            case .notAvailableAnymore:
                return (NSLocalizedString("Expired", comment: "Short label identifying content which has expired."), Color(.play_gray))
            case .available:
                if media.contentType == .scheduledLivestream {
                    return (NSLocalizedString("Live", comment: "Short label identifying a livestream. Display in uppercase.").uppercased(), color: Color(.play_liveRed))
                }
                else if media.play_isWebFirst {
                    return (NSLocalizedString("Web first", comment: "Web first label on media cells"), Color(.srg_blue))
                }
                else if let endDate = media.endDate, media.contentType == .episode, let remainingTime = Self.formattedDuration(from: now, to: endDate, format: .short) {
                    return (String(format: NSLocalizedString("%@ left", comment: "Short label displayed on a media expiring soon"), remainingTime), Color(.play_orange))
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
