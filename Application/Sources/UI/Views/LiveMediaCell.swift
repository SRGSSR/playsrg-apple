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
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .accessibilityElement()
                    .accessibilityOptionalLabel(accessibilityLabel(at: date))
                    .accessibility(addTraits: .isButton)
            }
            #else
            VisualView(media: media, programComposition: programComposition, date: date)
                .aspectRatio(16 / 9, contentMode: .fit)
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

struct LiveMediaCell_Previews: PreviewProvider {
    static private let liveMedia = Mock.liveMedia()
    static private let size = LayoutHorizontalCellSize(210, 16 / 9, 70)
    
    static var previews: some View {
        LiveMediaCell(media: liveMedia?.media, programComposition: liveMedia?.programComposition)
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
