//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import NukeUI
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct ChannelHeaderView: View {
    let channel: SRGChannel
    
    private var imageUrl: URL? {
        return url(for: channel.rawImage, size: .small, scaling: .preserveAspectRatio)
    }
    
    var body: some View {
        Group {
            if let imageUrl = imageUrl {
                LazyImage(source: imageUrl) { state in
                    if let image = state.image {
                        image
                            .aspectRatio(contentMode: .fit)
                            .frame(height: constant(iOS: 22, tvOS: 36))
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
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // See https://stackoverflow.com/a/68765719/760435
        .background(
            Color.srgGray23
                .shadow(color: Color(white: 0, opacity: 0.6), radius: 10, x: 0, y: 0)
                .mask(Rectangle().padding(.trailing, -40))
        )
        .accessibilityHidden(true)
    }
    
    private struct TitleView: View {
        let channel: SRGChannel
        
        var body: some View {
            Text(channel.title)
                .srgFont(.button)
                .lineLimit(1)
        }
    }
}

// MARK: Preview

struct ChannelHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelHeaderView(channel: Mock.channel())
            .previewLayout(.fixed(width: 100, height: 90))
    }
}
