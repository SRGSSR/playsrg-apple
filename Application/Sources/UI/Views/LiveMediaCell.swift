//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct LiveMediaCell: View, LiveMedia {
    let media: SRGMedia?
    
    @State var programComposition: SRGProgramComposition?
    @State private var channelObserver: Any?
    @State private var date = Date()
    
    private func registerForChannelUpdates() {
        guard let media = media,
              let channel = media.channel,
              media.contentType == .livestream else { return }
        channelObserver = ChannelService.shared.addObserverForUpdates(with: channel, livestreamUid: media.uid) { composition in
            programComposition = composition
            // TODO: Bad date updates. Use timer publisher
            date = Date()
        }
    }
    
    private func unregisterChannelUpdates() {
        ChannelService.shared.removeObserver(channelObserver)
    }
    
    var body: some View {
        Group {
            #if os(tvOS)
            ExpandingCardButton(action: action) {
                VisualView(media: media, programComposition: programComposition, date: date)
                    .aspectRatio(LiveMediaCellSize.aspectRatio, contentMode: .fit)
                    .unredactable()
                    .accessibilityElement()
                    .accessibilityOptionalLabel(accessibilityLabel(at: date))
                    .accessibility(addTraits: .isButton)
            }
            #else
            VisualView(media: media, programComposition: programComposition, date: date)
                .aspectRatio(LiveMediaCellSize.aspectRatio, contentMode: .fit)
                .redactable()
                .cornerRadius(LayoutStandardViewCornerRadius)
                .accessibilityElement()
                .accessibilityOptionalLabel(accessibilityLabel(at: date))
            #endif
        }
        .redactedIfNil(media)
        .onAppear {
            registerForChannelUpdates()
        }
        .onDisappear {
            unregisterChannelUpdates()
        }
    }
    
    #if os(tvOS)
    private func action() {
        if let media = media {
            navigateToMedia(media, play: true)
        }
    }
    #endif
    
    /// Behavior: h-exp, v-exp
    private struct VisualView: View, LiveMedia {
        let media: SRGMedia?
        let programComposition: SRGProgramComposition?
        let date: Date
        
        var body: some View {
            ZStack {
                ImageView(url: imageUrl(at: date, for: .small))
                Color(white: 0, opacity: 0.6)
                DescriptionView(media: media, programComposition: programComposition, date: date)
                BlockingOverlay(media: media)
                
                if let progress = progress(at: date) {
                    ProgressBar(value: progress)
                        .opacity(progress != 0 ? 1 : 0)
                        .frame(height: LayoutProgressBarHeight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View, LiveMedia {
        let media: SRGMedia?
        let programComposition: SRGProgramComposition?
        let date: Date
        
        var body: some View {
            VStack(alignment: .leading) {
                if let logoImage = logoImage {
                    Image(uiImage: logoImage)
                }
                
                Text(title(at: date))
                    .srgFont(.subtitle)
                    .lineLimit(2)
                
                if let subtitle = subtitle(at: date) {
                    Text(subtitle)
                        .srgFont(.overline)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

class LiveMediaCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    #if os(tvOS)
    private static let defaultItemWidth: CGFloat = 375
    #else
    private static let defaultItemWidth: CGFloat = 210
    #endif
    
    @objc static func swimlane() -> CGSize {
        return swimlane(itemWidth: defaultItemWidth)
    }
    
    @objc static func swimlane(itemWidth: CGFloat) -> CGSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio, 0)
    }
    
    @objc static func grid(layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> CGSize {
        return grid(approximateItemWidth: defaultItemWidth, layoutWidth: layoutWidth, spacing: spacing, minimumNumberOfColumns: minimumNumberOfColumns)
    }
    
    @objc static func grid(approximateItemWidth: CGFloat, layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> CGSize {
        return LayoutGridCellSize(approximateItemWidth, aspectRatio, 0, layoutWidth, spacing, minimumNumberOfColumns)
    }
}

struct LiveMediaCell_Previews: PreviewProvider {
    static private let liveMedia = Mock.liveMedia()
    static private let size = LiveMediaCellSize.swimlane()
    
    static var previews: some View {
        LiveMediaCell(media: liveMedia?.media, programComposition: liveMedia?.programComposition)
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
