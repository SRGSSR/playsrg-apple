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
        
        #if os(iOS)
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        #endif
        
        private var padding: CGFloat {
            #if os(iOS)
            if horizontalSizeClass == .compact {
                return LiveMediaCellSize.compactPadding
            }
            #endif
            return LiveMediaCellSize.regularPadding
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                if let logoImage = logoImage {
                    Image(uiImage: logoImage)
                        .padding(.bottom, 4)
                }
                
                Text(title(at: date))
                    .srgFont(.body)
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                if let subtitle = subtitle(at: date) {
                    Text(subtitle)
                        .srgFont(.caption)
                        .lineLimit(1)
                        .foregroundColor(.white)
                        .layoutPriority(1)
                }
            }
            .padding([.horizontal, .vertical], padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

class LiveMediaCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    fileprivate static let regularPadding: CGFloat = constant(iOS: 10, tvOS: 16)
    fileprivate static let compactPadding: CGFloat = 8
    
    private static let defaultItemWidth: CGFloat = constant(iOS: 210, tvOS: 375)
    
    @objc static func swimlane() -> NSCollectionLayoutSize {
        return swimlane(itemWidth: defaultItemWidth)
    }
    
    @objc static func swimlane(itemWidth: CGFloat) -> NSCollectionLayoutSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio, 0)
    }
    
    @objc static func grid(layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> NSCollectionLayoutSize {
        return grid(approximateItemWidth: defaultItemWidth, layoutWidth: layoutWidth, spacing: spacing, minimumNumberOfColumns: minimumNumberOfColumns)
    }
    
    @objc static func grid(approximateItemWidth: CGFloat, layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> NSCollectionLayoutSize {
        return LayoutGridCellSize(approximateItemWidth, aspectRatio, 0, layoutWidth, spacing, minimumNumberOfColumns)
    }
}

struct LiveMediaCell_Previews: PreviewProvider {
    static private let liveMedia = Mock.liveMedia()
    static private let size = LiveMediaCellSize.swimlane().previewSize
    
    static var previews: some View {
        #if os(tvOS)
        LiveMediaCell(media: liveMedia?.media, programComposition: liveMedia?.programComposition)
            .previewLayout(.fixed(width: size.width, height: size.height))
        #else
        Group {
            LiveMediaCell(media: liveMedia?.media, programComposition: liveMedia?.programComposition)
                .previewLayout(.fixed(width: size.width, height: size.height))
                .environment(\.horizontalSizeClass, .compact)
            LiveMediaCell(media: liveMedia?.media, programComposition: liveMedia?.programComposition)
                .previewLayout(.fixed(width: size.width, height: size.height))
                .environment(\.horizontalSizeClass, .regular)
        }
        #endif
    }
}
