//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct DurationLabel: View {
    let media: SRGMedia?
    
    private var properties: (text: String, color: Color)? {
        guard let media = media else { return nil }
        if media.contentType == .livestream || media.contentType == .scheduledLivestream {
            if media.blockingReason(at: Date()) == .startDate {
                return (NSLocalizedString("Soon", comment: "Short label identifying content which will be available soon."), Color(white: 0, opacity: 0.5))
            }
            else {
                return (NSLocalizedString("Live", comment: "Short label identifying a livestream."), Color(.play_red))
            }
        }
        else {
            return (PlayShortFormattedMinutes(media.duration / 1000), Color(white: 0, opacity: 0.5))
        }
    }
    
    var body: some View {
        if let properties = properties {
            Text(properties.text)
                .srgFont(.caption)
                .foregroundColor(.white)
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(properties.color)
                .cornerRadius(4)
        }
    }
}
