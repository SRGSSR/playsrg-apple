//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct MediaDescription {
    enum Style {
        /// Show information emphasis
        case show
        /// Date information emphasis
        case date
    }
    
    private static func placeholder(length: Int) -> String {
        return String(repeating: " ", count: length)
    }
    
    private static func formattedDuration(from: Date, to: Date) -> String? {
        guard let days = Calendar.current.dateComponents([.day], from: from, to: to).day else { return nil }
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
    
    static func title(for media: SRGMedia?, style: Style = .date) -> String {
        guard let media = media else { return placeholder(length: 15) }
        
        switch style {
        case .show:
            return media.show?.title ?? media.title
        case .date:
            return media.title
        }
    }
    
    static func subtitle(for media: SRGMedia?, style: Style = .date) -> String {
        guard let media = media else { return placeholder(length: 20) }
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
        guard let media = media else { return placeholder(length: 160) }
        return media.summary
    }
    
    static func availability(for media: SRGMedia?) -> String? {
        guard let media = media else { return placeholder(length: 25) }
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
}
