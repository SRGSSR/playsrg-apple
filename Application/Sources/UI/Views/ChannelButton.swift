//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct ChannelButton: View {
    let channel: SRGChannel?
    let action: () -> Void
    
    @Environment(\.isSelected) var isSelected
    
    private var imageUrl: URL? {
        return url(for: channel?.rawImage, size: .small, scaling: .preserveAspectRatio)
    }
    
    var body: some View {
        Button(action: action) {
            if let imageUrl = imageUrl {
                ImageView(url: imageUrl)
                    .aspectRatio(contentMode: .fit)
            }
            else if let title = channel?.title {
                Text(title)
                    .srgFont(.button)
                    .lineLimit(1)
            }
        }
        .frame(minWidth: 40, maxWidth: 120, minHeight: 22)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .foregroundColor(.srgGrayC7)
        .background(isSelected ? Color.srgGray4A : Color.srgGray23)
        .cornerRadius(100)
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
    }
}

// MARK: Accessibility

extension ChannelButton {
    var accessibilityLabel: String? {
        return channel?.title
    }
    
    var accessibilityHint: String? {
        return PlaySRGAccessibilityLocalizedString("Shows the channel programs", comment: "Channel selector button hint")
    }
}

// MARK: Preview

struct ChannelButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChannelButton(channel: nil, action: {})
            ChannelButton(channel: Mock.channel(), action: {})
            ChannelButton(channel: Mock.channel(.unknown), action: {})
            ChannelButton(channel: Mock.channel(.overflow), action: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
