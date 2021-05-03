//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

private enum BadgeMetrics {
    static let length: CGFloat = constant(iOS: 19, tvOS: 33)
    static let horizontalPadding: CGFloat = constant(iOS: 6, tvOS: 8)
    static let verticalPadding: CGFloat = constant(iOS: 2, tvOS: 5)
    static let cornerRadius: CGFloat = constant(iOS: 3, tvOS: 4)
}

/// Behavior: h-hug, v-hug
struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .srgFont(.label)
            .lineLimit(1)
            .foregroundColor(.white)
            .padding(.vertical, BadgeMetrics.verticalPadding)
            .padding(.horizontal, BadgeMetrics.horizontalPadding)
            .background(color)
            .cornerRadius(BadgeMetrics.cornerRadius)
    }
}

// Behavior: h-hug, v-hug
struct DurationBadge: View {
    let media: SRGMedia?
    
    private var duration: String? {
        guard let media = media, media.contentType != .livestream && media.contentType != .scheduledLivestream else { return nil }
        return PlayShortFormattedMinutes(media.duration / 1000)
    }
    
    var body: some View {
        if let duration = duration {
            Text(duration)
                .srgFont(.caption)
                .lineLimit(1)
                .foregroundColor(.white)
                .padding(.horizontal, BadgeMetrics.horizontalPadding)
                .frame(height: BadgeMetrics.length)
                .background(Color(.play_blackDurationLabelBackground))
                .cornerRadius(BadgeMetrics.cornerRadius)
        }
    }
}

/// Behavior: h-hug, v-hug
struct SubtitlesBadge: View {
    var body: some View {
        Text("ST")
            .srgFont(.caption)
            .lineLimit(1)
            .foregroundColor(.black)
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .background(Color(.play_whiteBadge))
            .cornerRadius(BadgeMetrics.cornerRadius)
    }
}

/// Behavior: h-hug, v-hug
struct AudioDescriptionBadge: View {
    var body: some View {
        Image("audio_description-24")
            .resizable()
            .foregroundColor(.black)
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .background(Color(.play_whiteBadge))
            .cornerRadius(BadgeMetrics.cornerRadius)
    }
}

/// Behavior: h-hug, v-hug
struct ThreeSixtyBadge: View {
    var body: some View {
        Image("360_media-25")
            .resizable()
            .foregroundColor(.white)
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
    }
}

/// Behhavior: h-hug, v-hug
struct YouthProtectionBadge: View {
    let color: SRGYouthProtectionColor?
    
    var body: some View {
        if let color = color, let image = YouthProtectionImageForColor(color) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: BadgeMetrics.length)
        }
    }
}

struct Badges_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Badge(text: "Badge", color: .orange)
            DurationBadge(media: Mock.media())
            SubtitlesBadge()
            AudioDescriptionBadge()
            ThreeSixtyBadge()
        }
        .padding()
        .background(Color.white)
        .previewLayout(.sizeThatFits)
        
        Group {
            YouthProtectionBadge(color: .yellow)
            YouthProtectionBadge(color: .red)
            ThreeSixtyBadge()
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
