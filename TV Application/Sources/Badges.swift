//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .srgFont(.caption)
            .foregroundColor(.white)
            .padding([.top, .bottom], 5)
            .padding([.leading, .trailing], 8)
            .background(color)
            .cornerRadius(4)
    }
}

struct AvailabilityBadge: View {
    let media: SRGMedia
    
    static func formattedDuration(from: Date, to: Date) -> String? {
        guard let days = Calendar.current.dateComponents([.day], from: from, to: to).day else { return nil }
        switch days {
        case 0:
            return PlayShortFormattedHours(to.timeIntervalSince(from))
        case 1...3:
            return PlayShortFormattedDays(to.timeIntervalSince(from))
        default:
            return nil
        }
    }
    
    private func availabilityBadgeProperties() -> (text: String, color: Color)? {
        let now = Date()
        let availability = media.timeAvailability(at: now)
        switch availability {
        case .notYetAvailable:
            return (NSLocalizedString("Soon", comment: "Short label identifying content which will be available soon."), Color(.play_gray))
        case .notAvailableAnymore:
            return (NSLocalizedString("Expired", comment: "Short label identifying content which has expired."), Color(.play_gray))
        case .available:
            guard let endDate = media.endDate, media.contentType != .livestream, media.contentType != .scheduledLivestream else { return nil }
            if let remainingTime = Self.formattedDuration(from: now, to: endDate) {
                return (String(format: NSLocalizedString("%@ left", comment: "Short label displayed on a media expiring soon"), remainingTime), Color(.play_orange))
            }
            else {
                return nil
            }
        default:
            return nil
        }
    }
    
    var body: some View {
        Group {
            if media.play_isWebFirst {
                Badge(text: NSLocalizedString("Web first", comment: "Web first label on media cells"), color: Color(.srg_blue))
            }
            else if let availabilityBadgeProperties = availabilityBadgeProperties() {
                Badge(text: availabilityBadgeProperties.text, color: availabilityBadgeProperties.color)
            }
        }
        .padding([.leading, .top], 8)
    }
}
