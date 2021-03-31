//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct FeaturedMediaCell: View {
    enum Layout {
        case hero
        case highlighted
    }
    
    let media: SRGMedia?
    let layout: Layout

    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                if let media = media {
                    navigateToMedia(media)
                }
            }) {
                HStack(spacing: 0) {
                    MediaVisualView(media: media, scale: .large)
                        .frame(width: geometry.size.height * 16 / 9, height: geometry.size.height)
                    DescriptionView(media: media, layout: layout)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(.srg_color(fromHexadecimalString: "#232323")!))
                .redacted(reason: redactionReason)
                .accessibilityElement()
                .accessibilityLabel(MediaDescription.accessibilityLabel(for: media))
                .accessibility(addTraits: .isButton)
            }
            .buttonStyle(CardButtonStyle())
        }
    }
    
    private struct DescriptionView: View {
        let media: SRGMedia?
        let layout: Layout
        
        private func textAlignment() -> TextAlignment {
            return layout == .highlighted ? .leading : .center
        }
        
        private func alignment() -> Alignment {
            return layout == .highlighted ? .leading : .center
        }

        var body: some View {
            VStack {
                Spacer()
                Text(MediaDescription.title(for: media, style: .show))
                    .srgFont(.subtitle)
                    .lineLimit(1)
                    .multilineTextAlignment(textAlignment())
                    .frame(maxWidth: .infinity, alignment: alignment())
                    .opacity(0.8)
                    .padding()
                Spacer()
                    .frame(height: 10)
                Text(MediaDescription.subtitle(for: media, style: .show))
                    .srgFont(.H2)
                    .lineLimit(2)
                    .multilineTextAlignment(textAlignment())
                    .frame(maxWidth: .infinity, alignment: alignment())
                    .padding()
                if let summary = MediaDescription.summary(for: media) {
                    Spacer()
                        .frame(height: 20)
                    Text(summary)
                        .srgFont(.body)
                        .lineLimit(4)
                        .multilineTextAlignment(textAlignment())
                        .frame(maxWidth: .infinity, alignment: alignment())
                        .opacity(0.8)
                        .padding()
                }
                if let media = media {
                    AvailabilityBadge(media: media)
                }
                Spacer()
            }
            .foregroundColor(.white)
        }
    }
}

struct FeaturedMediaCell_Previews: PreviewProvider {
    static var mediaPreview: SRGMedia {
        let asset = NSDataAsset(name: "media-rts-tv")!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        
        return try! MTLJSONAdapter(modelClass: SRGMedia.self)?.model(fromJSONDictionary: jsonData) as! SRGMedia
    }
    
    static var previews: some View {
        Group {
            FeaturedMediaCell(media: mediaPreview, layout: .hero)
                .previewLayout(.fixed(width: 1740, height: 680))
                .previewDisplayName("RTS media, hero layout")
            
            FeaturedMediaCell(media: mediaPreview, layout: .highlighted)
                .previewLayout(.fixed(width: 1740, height: 480))
                .previewDisplayName("RTS media, highlighted layout")
        }
    }
}
