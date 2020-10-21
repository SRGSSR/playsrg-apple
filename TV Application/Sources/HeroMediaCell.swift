//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct HeroMediaCell: View {
    let media: SRGMedia?
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                if let media = media {
                    navigateToMedia(media: media)
                }
            }) {
                HStack(spacing: 0) {
                    MediaVisual(media: media, scale: .large)
                        .frame(width: geometry.size.height * 16 / 9, height: geometry.size.height)
                    DescriptionView(media: media)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(.srg_color(fromHexadecimalString: "#232323")!))
                .redacted(reason: redactionReason)
            }
            .buttonStyle(CardButtonStyle())
            .animation(nil)
        }
    }
}

extension HeroMediaCell {
    private struct DescriptionView: View {
        let media: SRGMedia?
        
        var body: some View {
            VStack {
                Spacer()
                Text(MediaDescription.title(for: media))
                    .srgFont(.regular, size: .subheadline)
                    .lineLimit(1)
                    .opacity(0.8)
                Spacer()
                    .frame(height: 10)
                Text(MediaDescription.subtitle(for: media))
                    .srgFont(.medium, size: .title)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding()
                if let summary = MediaDescription.summary(for: media) {
                    Spacer()
                        .frame(height: 20)
                    Text(summary)
                        .srgFont(.regular, size: .subtitle)
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                        .padding()
                }
                Spacer()
            }
            .foregroundColor(.white)
        }
    }
}
