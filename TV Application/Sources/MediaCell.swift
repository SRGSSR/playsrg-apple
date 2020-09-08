//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct MediaCell: View {
    private struct DescriptionView: View {
        let media: SRGMedia?
        
        var body: some View {
            Text(MediaDescription.title(for: media))
                .srgFont(.regular, size: .subtitle)
                .lineLimit(2)
            Text(MediaDescription.subtitle(for: media))
                .srgFont(.regular, size: .caption)
                .lineLimit(1)
        }
    }
    
    let media: SRGMedia?
    
    @Environment(\.isFocused) private var isFocused: Bool
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                MediaVisual(media: media, scale: .small, contentMode: .fit) {
                    Rectangle()
                        .fill(Color.clear)
                }
                .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                .cornerRadius(12)
                .shadow(radius: isFocused ? 20 : 0)
                
                DescriptionView(media: media)
                    .opacity(isFocused ? 1 : 0.5)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            .scaleEffect(isFocused ? 1.1 : 1)
            .offset(x: 0, y: isFocused ? 10 : 0)
            .redacted(reason: redactionReason)
            .animation(.default)
        }
    }
}
