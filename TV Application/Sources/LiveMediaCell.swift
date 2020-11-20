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
    let media: SRGMedia?
    
    @State var channelObserver: Any?
    @State var programComposition: SRGProgramComposition?
    @State var date = Date()
    
    @State private var isFocused: Bool = false
    
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
            return channel.play_logo32Image
        }
        else if let media = media {
            return media.mediaType == .audio ? RadioChannelLogo32Image(nil) : TVChannelLogo32Image(nil)
        }
        else {
            return nil
        }
    }
    
    private var progress: Double? {
        guard channel != nil else { return nil }
        guard let currentProgram = program(at: date) else { return 1 }
        return date.timeIntervalSince(currentProgram.startDate) / currentProgram.endDate.timeIntervalSince(currentProgram.startDate)
    }
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
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
            VStack {
                Button(action: {
                    if let media = media {
                        navigateToMedia(media)
                    }
                }) {
                    ZStack {
                        ImageView(url: imageUrl)
                            .whenRedacted { $0.hidden() }
                        Rectangle()
                            .fill(Color(white: 0, opacity: 0.6))
                        if let logoImage = logoImage {
                            Image(uiImage: logoImage)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .whenRedacted { $0.hidden() }
                                .padding()
                        }
                        if let progress = progress {
                            ProgressView(value: progress)
                                .accentColor(Color(UIColor.play_progressRed))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .padding()
                        }
                        BlockingOverlay(media: media)
                            .whenRedacted { $0.hidden() }
                    }
                    .onFocusChange { isFocused = $0 }
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                }
                .buttonStyle(CardButtonStyle())
                
                DescriptionView(media: media, programComposition: programComposition, date: date)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .opacity(isFocused ? 1 : 0.5)
                    .offset(x: 0, y: isFocused ? 10 : 0)
                    .scaleEffect(isFocused ? 1.1 : 1, anchor: .top)
                    .animation(.easeInOut(duration: 0.2))
            }
            .redacted(reason: redactionReason)
        }
        .onAppear {
            registerForChannelUpdates()
        }
        .onDisappear {
            unregisterChannelUpdates()
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
            guard let currentProgram = program(at: date) else { return nil }
            let remainingTimeInterval = currentProgram.endDate.timeIntervalSince(date)
            let remainingTime = DurationFormatters.remainingTime(for: remainingTimeInterval)
            return NSLocalizedString("\(remainingTime) remaining", comment: "Text displayed on live cells telling how much time remains for a program currently on air")
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .srgFont(.medium, size: .subtitle)
                    .lineLimit(2)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .srgFont(.light, size: .subtitle)
                        .lineLimit(2)
                }
            }
        }
    }
}
