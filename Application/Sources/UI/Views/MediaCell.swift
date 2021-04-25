//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct MediaCell: View {
    enum Layout {
        case vertical
        case horizontal
        case adaptive
    }
    
    let media: SRGMedia?
    let style: MediaDescription.Style
    let layout: Layout
    let action: (() -> Void)?
    
    fileprivate var onFocusAction: ((Bool) -> Void)?
    
    @State private var isFocused = false
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #endif
    
    init(media: SRGMedia?, style: MediaDescription.Style = .date, layout: Layout = .adaptive, action: (() -> Void)? = nil) {
        self.media = media
        self.style = style
        self.layout = layout
        self.action = action
    }
        
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            #if os(tvOS)
            LabeledCardButton(action: action ?? {
                if let media = media {
                    navigateToMedia(media)
                }
            }) {
                ZStack {
                    MediaVisualView(media: media, scale: .small, contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                        .onParentFocusChange { focused in
                            isFocused = focused
                            
                            if let onFocusAction = self.onFocusAction {
                                onFocusAction(focused)
                            }
                        }
                        .accessibilityElement()
                        .accessibilityLabel(MediaDescription.accessibilityLabel(for: media))
                        .accessibility(addTraits: .isButton)
                        
                    if let media = media {
                        AvailabilityBadge(media: media)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .accessibility(hidden: true)
                    }
                }
            } label: {
                DescriptionView(media: media, style: style)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            #else
            Group {
                if layout == .horizontal || (layout == .adaptive && horizontalSizeClass == .compact) {
                    HStack {
                        MediaVisualView(media: media, scale: .small, contentMode: .fit)
                            .frame(width: geometry.size.height * 16 / 9, height: geometry.size.height)
                            .cornerRadius(LayoutStandardViewCornerRadius)
                        DescriptionView(media: media, style: style)
                            .frame(maxWidth: .infinity, maxHeight: geometry.size.height, alignment: .topLeading)
                    }
                }
                else {
                    VStack {
                        MediaVisualView(media: media, scale: .small, contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                            .cornerRadius(LayoutStandardViewCornerRadius)
                        DescriptionView(media: media, style: style)
                            .frame(width: geometry.size.width, alignment: .leading)
                    }
                }
            }
            .accessibilityElement()
            .accessibilityLabel(MediaDescription.accessibilityLabel(for: media))
            #endif
        }
        .redacted(reason: redactionReason)
    }
    
    private struct DescriptionView: View {
        let media: SRGMedia?
        let style: MediaDescription.Style
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(MediaDescription.title(for: media, style: style))
                    .srgFont(.subtitle)
                    .lineLimit(2)
                Text(MediaDescription.subtitle(for: media, style: style))
                    .srgFont(style == .date ? .overline : .H4)
                    .lineLimit(2)
                    .layoutPriority(1)
            }
        }
    }
}

extension MediaCell {
    func onFocus(perform action: @escaping (Bool) -> Void) -> MediaCell {
        var mediaCell = self
        mediaCell.onFocusAction = action
        return mediaCell
    }
}

struct MediaCell_Previews: PreviewProvider {
    static var mediaPreview: SRGMedia {
        let asset = NSDataAsset(name: "media-rts-tv")!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        
        return try! MTLJSONAdapter(modelClass: SRGMedia.self)?.model(fromJSONDictionary: jsonData) as! SRGMedia
    }
    
    static var previews: some View {
        Group {
            MediaCell(media: mediaPreview)
                .previewLayout(.fixed(width: 375, height: 400))
                .previewDisplayName("RTS media, default date style")
            
            MediaCell(media: mediaPreview, style: .show)
                .previewLayout(.fixed(width: 375, height: 400))
                .previewDisplayName("RTS media, show style")
        }
    }
}
