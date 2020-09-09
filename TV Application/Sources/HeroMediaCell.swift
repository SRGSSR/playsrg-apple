//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct HeroMediaCell: View {
    private struct DescriptionView: View {
        let media: SRGMedia?
        
        var body: some View {
            VStack {
                Text(MediaDescription.title(for: media))
                    .srgFont(.bold, size: .title)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(MediaDescription.subtitle(for: media))
                    .srgFont(.medium, size: .headline)
                    .lineLimit(1)
                    .opacity(0.6)
            }
            .foregroundColor(.white)
        }
    }
    
    let media: SRGMedia?
    
    @Environment(\.isFocused) private var isFocused: Bool
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MediaVisual(media: media, scale: .large, contentMode: .fill) {
                    Rectangle()
                        .fill(Color(white: 0, opacity: 0.4))
                    DescriptionView(media: media)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(60)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .cornerRadius(12)
            .shadow(radius: isFocused ? 20 : 0)
            .scaleEffect(isFocused ? 1.02 : 1)
            .redacted(reason: redactionReason)
            .animation(.default)
        }
    }
}
