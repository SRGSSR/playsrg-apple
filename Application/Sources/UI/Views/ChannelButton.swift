//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

/// Behavior: h-hug, v-hug
struct ChannelButton: View {
    let channel: SRGChannel
    let accessibilityHint: String?
    let action: () -> Void
        
    init(_ channel: SRGChannel, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.channel = channel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(channel.title)
                .srgFont(.button)
                .lineLimit(1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .foregroundColor(.srgGrayC7)
        .background(Color.srgGray23)
        .cornerRadius(100)
        .accessibilityElement(label: channel.title, hint: accessibilityHint, traits: .isButton)
    }
}

struct ChannelButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChannelButton(Mock.channel(.logo16_9), action: {})
                .padding()
                .previewLayout(.sizeThatFits)
            ChannelButton(Mock.channel(.logo3_1), action: {})
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
