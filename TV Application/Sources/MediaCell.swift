//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct MediaCell: View {
    let media: SRGMedia?
    let style: MediaDescription.Style
    let action: (() -> Void)?
    
    fileprivate var onFocusAction: ((Bool) -> Void)? = nil
    
    @State private var isFocused: Bool = false
    
    init(media: SRGMedia?, style: MediaDescription.Style = .date, action: (() -> Void)? = nil) {
        self.media = media
        self.style = style
        self.action = action
    }
        
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Button(action: action ?? {
                    if let media = media {
                        navigateToMedia(media)
                    }
                }) {
                    MediaVisualView(media: media, scale: .small, contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                        .onFocusChange { focused in
                            isFocused = focused
                            
                            if let onFocusAction = self.onFocusAction {
                                onFocusAction(focused)
                            }
                        }
                }
                .buttonStyle(CardButtonStyle())
                
                DescriptionView(media: media, style: style)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .animation(nil)
                    .opacity(isFocused ? 1 : 0.5)
                    .offset(x: 0, y: isFocused ? 10 : 0)
                    .scaleEffect(isFocused ? 1.1 : 1, anchor: .top)
                    .animation(.easeInOut(duration: 0.2))
            }
            .redacted(reason: redactionReason)
        }
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
                    .srgFont(.headline2)
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
