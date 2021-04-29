//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// Behavior: h-hug, v-hug
struct DurationLabel: View {
    let media: SRGMedia?
    
    private var duration: String? {
        guard let media = media, media.contentType != .livestream && media.contentType != .scheduledLivestream else { return nil }
        return PlayShortFormattedMinutes(media.duration / 1000)
    }
    
    var body: some View {
        if let duration = duration {
            Text(duration)
                .srgFont(.caption)
                .foregroundColor(.white)
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(Color(.play_blackDurationLabelBackground))
                .cornerRadius(4)
        }
    }
}

struct DurationLabel_Preview: PreviewProvider {
    static var previews: some View {
        DurationLabel(media: Mock.media())
            .padding()
            .background(Color.white)
            .previewLayout(.sizeThatFits)
    }
}
