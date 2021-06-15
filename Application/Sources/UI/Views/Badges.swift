//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

private enum BadgeMetrics {
    static let length: CGFloat = constant(iOS: 19, tvOS: 33)
    static let horizontalPadding: CGFloat = constant(iOS: 6, tvOS: 8)
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
            .padding(.vertical, constant(iOS: 2, tvOS: 5))
            .padding(.horizontal, BadgeMetrics.horizontalPadding)
            .background(color)
            .cornerRadius(BadgeMetrics.cornerRadius)
    }
}

// Behavior: h-hug, v-hug
struct DurationBadge: View {
    let duration: Double
    
    var body: some View {
        Text(PlayShortFormattedMinutes(duration))
            .srgFont(.caption)
            .lineLimit(1)
            .foregroundColor(.white)
            .padding(.horizontal, BadgeMetrics.horizontalPadding)
            .frame(height: BadgeMetrics.length)
            .background(Color(.play_blackDurationLabelBackground))
            .cornerRadius(BadgeMetrics.cornerRadius)
    }
}

/// Behavior: h-hug, v-hug
struct SubtitlesBadge: View {
    var body: some View {
        Image("subtitles-24")
            .resizable()
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .cornerRadius(BadgeMetrics.cornerRadius)
    }
}

/// Behavior: h-hug, v-hug
struct AudioDescriptionBadge: View {
    var body: some View {
        Image("audio_description-24")
            .resizable()
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .cornerRadius(BadgeMetrics.cornerRadius)
    }
}

/// Behavior: h-hug, v-hug
struct MultiAudioBadge: View {
    var body: some View {
        Image("multiaudio-24")
            .resizable()
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .cornerRadius(BadgeMetrics.cornerRadius)
    }
}

/// Behavior: h-hug, v-hug
struct ThreeSixtyBadge: View {
    var body: some View {
        Image("360_media-24")
            .resizable()
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
    }
}

/// Behhavior: h-hug, v-hug
struct YouthProtectionBadge: View {
    let color: SRGYouthProtectionColor
    
    var body: some View {
        if let image = YouthProtectionImageForColor(color) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: BadgeMetrics.length)
        }
    }
}

struct Badges_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            Badge(text: "Badge", color: .orange)
            DurationBadge(duration: 1234)
            SubtitlesBadge()
            AudioDescriptionBadge()
            MultiAudioBadge()
            ThreeSixtyBadge()
        }
        .padding()
        .background(Color.white)
        .previewLayout(.sizeThatFits)
        
        HStack {
            YouthProtectionBadge(color: .yellow)
            YouthProtectionBadge(color: .red)
            YouthProtectionBadge(color: .none)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
