//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct DurationLabel: View {
    let media: SRGMedia?
    
    private var isLivestream: Bool {
        guard let media = media else { return false }
        return media.contentType == .livestream || media.contentType == .scheduledLivestream
    }
    
    private var duration: String? {
        guard let media = media else { return nil }
        if isLivestream {
            return NSLocalizedString("Live", comment: "Short label identifying a livestream. Display in uppercase.")
        }
        else {
            return PlayShortFormattedMinutes(media.duration / 1000)
        }
    }
    
    var body: some View {
        if let duration = duration {
            Text(duration)
                .srgFont(.medium, size: .caption)
                .foregroundColor(.white)
                .padding([.top, .bottom], 5)
                .padding([.leading, .trailing], 8)
                .background(isLivestream ? Color(.play_liveRed) : Color(white: 0, opacity: 0.5))
                .cornerRadius(4)
        }
    }
}
