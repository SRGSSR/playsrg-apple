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
    let accessibilityHint: String?
    let action: () -> Void
    
    @Environment(\.isSelected) var isSelected
        
    init(_ channel: SRGChannel?, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.channel = channel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    private var logoImage: UIImage? {
        guard let channel = channel, let tvChannel = ApplicationConfiguration.shared.tvChannel(forUid: channel.uid) else { return nil }
        return TVChannelLogoImage(tvChannel)
    }
    
    var body: some View {
        Button(action: action) {
            if let image = logoImage {
                Image(uiImage: image)
            }
            else if let title = channel?.title {
                Text(title)
                    .srgFont(.button)
                    .lineLimit(1)
            }
        }
        .frame(minWidth: 40, minHeight: 22)
        .redactedIfNil(channel)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .foregroundColor(.srgGrayC7)
        .background(isSelected ? Color.srgGray4A : Color.srgGray23)
        .cornerRadius(100)
        .accessibilityElement(label: channel?.title, hint: accessibilityHint, traits: .isButton)
    }
}

// MARK: Preview

struct ChannelButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChannelButton(nil, action: {})
                .padding()
                .previewLayout(.sizeThatFits)
            ChannelButton(Mock.channel(.logo16_9), action: {})
                .padding()
                .previewLayout(.sizeThatFits)
            ChannelButton(Mock.channel(.logo3_1), action: {})
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
