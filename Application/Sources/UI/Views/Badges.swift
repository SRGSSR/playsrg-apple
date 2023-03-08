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
    let textColor: Color
    
    init(text: String, color: Color, textColor: Color = .white) {
        self.text = text
        self.color = color
        self.textColor = textColor
    }
    
    var body: some View {
        Text(text)
            .srgFont(.label)
            .textCase(.uppercase)
            .lineLimit(1)
            .truncationMode(.head)
            .foregroundColor(textColor)
            .padding(.top, constant(iOS: 2, tvOS: 5))
            .padding(.bottom, constant(iOS: 2, tvOS: 4))
            .padding(.horizontal, BadgeMetrics.horizontalPadding)
            .background(color)
            .cornerRadius(BadgeMetrics.cornerRadius)
    }
}

/// Behavior: h-hug, v-hug
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
        Image(decorative: "subtitles")
            .resizable()
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .cornerRadius(BadgeMetrics.cornerRadius)
            .accessibilityElement(label: PlaySRGAccessibilityLocalizedString("Subtitled", comment: "Accessibility label for the subtitled badge"))
    }
}

/// Behavior: h-hug, v-hug
struct AudioDescriptionBadge: View {
    var body: some View {
        Image(decorative: "audio_description")
            .resizable()
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .cornerRadius(BadgeMetrics.cornerRadius)
            .accessibilityElement(label: PlaySRGAccessibilityLocalizedString("Audio described", comment: "Accessibility label for the audio description badge"))
    }
}

/// Behavior: h-hug, v-hug
struct SignLanguageBadge: View {
    var body: some View {
        Image(decorative: "sign_language")
            .resizable()
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .cornerRadius(BadgeMetrics.cornerRadius)
            .accessibilityElement(label: PlaySRGAccessibilityLocalizedString("Sign Language", comment: "Accessibility label for the sign Language badge"))
    }
}

/// Behavior: h-hug, v-hug
struct MultiAudioBadge: View {
    var body: some View {
        Image(decorative: "multiaudio")
            .resizable()
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .cornerRadius(BadgeMetrics.cornerRadius)
            .accessibilityElement(label: PlaySRGAccessibilityLocalizedString("Original version", comment: "Accessibility label for the multi audio badge"))
    }
}

/// Behavior: h-hug, v-hug
struct DolbyDigitalBadge: View {
    var body: some View {
        Image(decorative: "dolby_digital")
            .resizable()
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .cornerRadius(BadgeMetrics.cornerRadius)
            .accessibilityElement(label: PlaySRGAccessibilityLocalizedString("Dolby Digital sound", comment: "Accessibility label for the Dolby Digital sound badge"))
    }
}

/// Behavior: h-hug, v-hug
struct ThreeSixtyBadge: View {
    var body: some View {
        Image(decorative: "360_media")
            .resizable()
            .frame(width: BadgeMetrics.length, height: BadgeMetrics.length)
            .accessibilityElement(label: PlaySRGAccessibilityLocalizedString("360-degree content", comment: "Accessibility label for the 360 badge"))
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
                .accessibilityElement(label: SRGMessageForYouthProtectionColor(color))
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
            SignLanguageBadge()
            MultiAudioBadge()
            DolbyDigitalBadge()
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
