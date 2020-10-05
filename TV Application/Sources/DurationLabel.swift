//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct DurationLabel: View {
    let media: SRGMedia?
    
    private var duration: String? {
        guard let media = media else { return nil }
        let isLivestreamOrScheduledLivestream = (media.contentType == SRGContentType.livestream || media.contentType == SRGContentType.scheduledLivestream)
        if isLivestreamOrScheduledLivestream {
            return NSLocalizedString("Live", comment: "Short label identifying a livestream. Display in uppercase.")
        }
        else {
            return DurationFormatters.shortMinutes(for: media.duration / 1000)
        }
    }
    
    var body: some View {
        if let duration = duration {
            Text(duration)
                .srgFont(.medium, size: .caption)
                .foregroundColor(.white)
                .padding([.top, .bottom], 5)
                .padding([.leading, .trailing], 8)
                .background(Color.init(white: 0, opacity: 0.5))
                .cornerRadius(4)
        }
    }
}
