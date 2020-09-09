//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct HeroMediaCell: View {
    private struct DescriptionView: View {
        let media: SRGMedia?
        
        var body: some View {
            VStack {
                Spacer()
                Text(MediaDescription.title(for: media))
                    .srgFont(.regular, size: .subtitle)
                    .lineLimit(1)
                    .opacity(0.8)
                Spacer()
                    .frame(height: 20)
                Text(MediaDescription.subtitle(for: media))
                    .srgFont(.medium, size: .title)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                if let summary = MediaDescription.summary(for: media) {
                    Spacer()
                        .frame(height: 40)
                    Text(summary)
                        .srgFont(.regular, size: .subtitle)
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                }
                Spacer()
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
            HStack(spacing: 0) {
                MediaVisual(media: media, scale: .large)
                    .frame(width: geometry.size.height * 16 / 9, height: geometry.size.height)
                DescriptionView(media: media)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color(.srg_color(fromHexadecimalString: "#333333")!))
            .cornerRadius(12)
            .shadow(radius: isFocused ? 20 : 0)
            .scaleEffect(isFocused ? 1.02 : 1)
            .redacted(reason: redactionReason)
            .animation(.default)
        }
    }
}
