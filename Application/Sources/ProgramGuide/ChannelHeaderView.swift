//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct ChannelHeaderView: View {
    let channel: SRGChannel
    
    private var logoImage: UIImage? {
        guard let tvChannel = ApplicationConfiguration.shared.tvChannel(forUid: channel.uid) else { return nil }
        return TVChannelLargeLogoImage(tvChannel)
    }
    
    var body: some View {
        Group {
            if let image = logoImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 62)
            }
            else {
                Text(channel.title)
                    .srgFont(.button)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // See https://stackoverflow.com/a/68765719/760435
        .background(
            Color.srgGray23
                .shadow(color: Color(white: 0, opacity: 0.6), radius: 10, x: 0, y: 0)
                .mask(Rectangle().padding(.trailing, -40))
        )
        .accessibilityHidden(true)
    }
}

// MARK: Preview

struct ChannelHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelHeaderView(channel: Mock.channel())
            .previewLayout(.fixed(width: 100, height: 90))
    }
}
