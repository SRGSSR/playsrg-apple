//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//
import SwiftUI

struct LiveMediaCell: View, LiveMedia {
    enum Layout {
        case overprint
        case vertical
    }
    
    let media: SRGMedia?
    let layout: Layout
    
    @State var programComposition: SRGProgramComposition?
    @State private var channelObserver: Any?
    @State private var date = Date()
    @State private var isFocused = false
    
    private var accessibilityLabel: String? {
        if let channel = channel {
            var label = String(format: PlaySRGAccessibilityLocalizedString("%@ live", "Live content label, with a channel title"), channel.title)
            if let currentProgram = program(at: Date()) {
                label.append(", \(currentProgram.title)")
            }
            return label
        }
        else {
            return MediaDescription.accessibilityLabel(for: media)
        }
    }
    
    private func registerForChannelUpdates() {
        guard let media = media,
              let channel = media.channel,
              media.contentType == .livestream else { return }
        channelObserver = ChannelService.shared.addObserverForUpdates(with: channel, livestreamUid: media.uid) { composition in
            programComposition = composition
            date = Date()
        }
    }
    
    private func unregisterChannelUpdates() {
        ChannelService.shared.removeObserver(channelObserver)
    }
    
    var body: some View {
        GeometryReader { geometry in
            #if os(tvOS)
            LabeledCardButton(action: action) {
                VisualView(media: media, programComposition: programComposition, date: date, layout: .vertical)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                    .onParentFocusChange { isFocused = $0 }
                    .accessibilityElement()
                    .accessibilityOptionalLabel(accessibilityLabel)
                    .accessibility(addTraits: .isButton)
            } label: {
                DescriptionView(media: media, programComposition: programComposition, date: date)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            #else
            VStack {
                VisualView(media: media, programComposition: programComposition, date: date, layout: layout)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                    .cornerRadius(LayoutStandardViewCornerRadius)
                if layout == .vertical {
                    DescriptionView(media: media, programComposition: programComposition, date: date)
                        .frame(width: geometry.size.width, alignment: .leading)
                }
            }
            .accessibilityElement()
            .accessibilityOptionalLabel(accessibilityLabel)
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
    
    private struct VisualView: View, LiveMedia {
        let media: SRGMedia?
        let programComposition: SRGProgramComposition?
        let date: Date
        let layout: Layout
        
        var body: some View {
            ZStack {
                ImageView(url: imageUrl(at: date, for: .small))
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.6))
                VStack {
                    if let logoImage = logoImage {
                        Image(uiImage: logoImage)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                    #if os(iOS)
                    if layout == .overprint {
                        DescriptionView(media: media, programComposition: programComposition, date: date)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                    #endif
                }
                .padding()
                BlockingOverlay(media: media)
                if let media = media, media.timeAvailability(at: Date()) == .notYetAvailable {
                    Badge(text: NSLocalizedString("Soon", comment: "Short label identifying content which will be available soon."), color: Color(.play_gray))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding([.top, .leading], 8)
                }
                
                if let progress = progress(at: date) {
                    ProgressBar(value: progress)
                        .opacity(progress != 0 ? 1 : 0)
                        .frame(height: LayoutProgressBarHeight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }
    
    private struct DescriptionView: View, LiveMedia {
        let media: SRGMedia?
        let programComposition: SRGProgramComposition?
        let date: Date
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title(at: date))
                    .srgFont(.subtitle)
                    .lineLimit(2)
                
                if let subtitle = subtitle(at: date) {
                    Text(subtitle)
                        .srgFont(.overline)
                        .lineLimit(2)
                }
            }
        }
    }
}
