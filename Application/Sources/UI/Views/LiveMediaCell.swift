//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//
import SwiftUI

protocol LiveMediaData {
    var media: SRGMedia? { get }
    var programComposition: SRGProgramComposition? { get }
}

extension LiveMediaData {
    var channel: SRGChannel? {
        return programComposition?.channel ?? media?.channel
    }
    
    func program(at date: Date) -> SRGProgram? {
        return programComposition?.play_program(at: date)
    }
}

struct LiveMediaCell: View, LiveMediaData {
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
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    private var accessibilityLabel: String {
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
            LabeledCardButton(action: {
                if let media = media {
                    navigateToMedia(media, play: true)
                }
            }) {
                VisualView(media: media, programComposition: programComposition, date: date, layout: .vertical)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                    .onParentFocusChange { isFocused = $0 }
                    .accessibilityElement()
                    .accessibilityLabel(accessibilityLabel)
                    .accessibility(addTraits: .isButton)
            } label: {
                VStack {
                    ProgressView(media: media, programComposition: programComposition, date: date)
                    DescriptionView(media: media, programComposition: programComposition, date: date)
                        .frame(width: geometry.size.width, alignment: .leading)
                }
            }
            #else
            VStack {
                VisualView(media: media, programComposition: programComposition, date: date, layout: layout)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                    .cornerRadius(LayoutStandardViewCornerRadius)
                ProgressView(media: media, programComposition: programComposition, date: date)
                if layout == .vertical {
                    DescriptionView(media: media, programComposition: programComposition, date: date)
                        .frame(width: geometry.size.width, alignment: .leading)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
            #endif
        }
        .redacted(reason: redactionReason)
        .onAppear {
            registerForChannelUpdates()
        }
        .onDisappear {
            unregisterChannelUpdates()
        }
    }
    
    private struct VisualView: View, LiveMediaData {
        let media: SRGMedia?
        let programComposition: SRGProgramComposition?
        let date: Date
        let layout: Layout
        
        private var imageUrl: URL? {
            let width = SizeForImageScale(.small).width
            if let channel = channel {
                return program(at: date)?.imageURL(for: .width, withValue: width, type: .default) ?? channel.imageURL(for: .width, withValue: width, type: .default)
            }
            else {
                return media?.imageURL(for: .width, withValue: width, type: .default)
            }
        }
        
        private var logoImage: UIImage? {
            if let channel = channel {
                #if os(tvOS)
                return channel.play_logo60Image
                #else
                return channel.play_logo32Image
                #endif
            }
            else {
                return nil
            }
        }
        
        var body: some View {
            ZStack {
                ImageView(url: imageUrl)
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
                        .padding([.leading, .top], 8)
                }
            }
        }
    }
    
    private struct DescriptionView: View, LiveMediaData {
        let media: SRGMedia?
        let programComposition: SRGProgramComposition?
        let date: Date
        
        private var title: String {
            if let channel = channel {
                return program(at: date)?.title ?? channel.title
            }
            else {
                return MediaDescription.title(for: media)
            }
        }
        
        private var subtitle: String? {
            if let media = media, media.contentType == .scheduledLivestream {
                return MediaDescription.subtitle(for: media)
            }
            else {
                guard let currentProgram = program(at: date) else { return nil }
                let remainingTimeInterval = currentProgram.endDate.timeIntervalSince(date)
                let remainingTime = PlayRemainingTimeFormattedDuration(remainingTimeInterval)
                return String(format: NSLocalizedString("%@ remaining", comment: "Text displayed on live cells telling how much time remains for a program currently on air"), remainingTime)
            }
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .srgFont(.subtitle)
                    .lineLimit(2)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .srgFont(.overline)
                        .lineLimit(2)
                }
            }
        }
    }
    
    private struct ProgressView: View, LiveMediaData {
        let media: SRGMedia?
        let programComposition: SRGProgramComposition?
        let date: Date
        
        private var progress: Double? {
            if channel != nil {
                guard let currentProgram = program(at: date) else { return 1 }
                return date.timeIntervalSince(currentProgram.startDate) / currentProgram.endDate.timeIntervalSince(currentProgram.startDate)
            }
            else if let media = media, media.contentType == .scheduledLivestream, media.timeAvailability(at: Date()) == .available,
                    let startDate = media.startDate,
                    let endDate = media.endDate {
                let progress = Date().timeIntervalSince(startDate) / endDate.timeIntervalSince(startDate)
                return progress.clamped(to: 0...1)
            }
            else {
                return nil
            }
        }
        
        var body: some View {
            if let progress = progress {
                ProgressBar(value: progress)
                    .frame(maxWidth: .infinity, maxHeight: LayoutProgressBarHeight)
                    .cornerRadius(4)
            }
        }
    }
}
