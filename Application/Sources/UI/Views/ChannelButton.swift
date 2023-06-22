//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import NukeUI
import SRGAppearanceSwift
import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct ChannelButton: View {
    let channel: SRGChannel?
    let action: () -> Void
    
    @Environment(\.isSelected) var isSelected
    
    private var imageUrl: URL? {
        return url(for: channel?.rawImage, size: .small, scalingService: .centralized)
    }
    
    var body: some View {
        Button(action: action) {
            if let imageUrl {
                LazyImage(source: imageUrl) { state in
                    if let image = state.image {
                        image
                            .resizingMode(.aspectFit)
                    }
                    else {
                        TitleView(channel: channel)
                    }
                }
            }
            else {
                TitleView(channel: channel)
            }
        }
        .frame(minWidth: 40, maxWidth: 120, maxHeight: 22)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .foregroundColor(.srgGrayC7)
        .background(isSelected ? Color.srgGray4A : Color.srgGray23)
        .cornerRadius(100)
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
    }
    
    private struct TitleView: View {
        let channel: SRGChannel?
        
        var body: some View {
            if let title = channel?.title {
                Text(title)
                    .srgFont(.button)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: Accessibility

private extension ChannelButton {
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
            ChannelButton(channel: Mock.channel(.standardWithoutLogo), action: {})
            ChannelButton(channel: Mock.channel(.overflowWithoutLogo), action: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
