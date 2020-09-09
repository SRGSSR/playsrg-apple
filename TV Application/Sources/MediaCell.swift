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
                .srgFont(.medium, size: .subtitle)
                .lineLimit(2)
            Text(MediaDescription.subtitle(for: media))
                .srgFont(.light, size: .subtitle)
                .lineLimit(2)
        }
    }
    
    private struct Appearance {
        let shadowRadius: CGFloat
        let opacity: Double
        let scale: CGFloat
    }
    
    let media: SRGMedia?
    
    @Environment(\.isFocused) private var isFocused: Bool
    @Environment(\.isPressed) private var isPressed: Bool
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    private var appearance: Appearance {
        if isPressed {
            return Appearance(shadowRadius: 10, opacity: 1, scale: 1.05)
        }
        else if isFocused {
            return Appearance(shadowRadius: 20, opacity: 1, scale: 1.1)
        }
        else {
            return Appearance(shadowRadius: 0, opacity: 0.5, scale: 1)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                MediaVisual(media: media, scale: .small, contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                    .cornerRadius(12)
                    .shadow(radius: appearance.shadowRadius)
                
                DescriptionView(media: media)
                    .opacity(appearance.opacity)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            .scaleEffect(appearance.scale)
            .redacted(reason: redactionReason)
            .animation(.default)
        }
    }
}
