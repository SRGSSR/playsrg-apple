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
    
    var currentProgram: SRGProgram? {
        return programComposition?.play_program(at: Date())
    }
}

struct LiveMediaCell: View, LiveMediaData {
    let media: SRGMedia?
    
    @State var channelObserver: Any?
    @State var programComposition: SRGProgramComposition?
    
    @State private var isFocused: Bool = false
    
    private var imageUrl: URL? {
        let width = SizeForImageScale(.small).width
        if let channel = channel {
            return currentProgram?.imageURL(for: .width, withValue: width, type: .default) ?? channel.imageURL(for: .width, withValue: width, type: .default)
        }
        else {
            return media?.imageURL(for: .width, withValue: width, type: .default)
        }
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
                            .onFocusChange { isFocused = $0 }
                            .whenRedacted { $0.hidden() }
                        Rectangle()
                            .fill(Color(white: 0, opacity: 0.6))
                        BlockingOverlay(media: media)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                }
                .buttonStyle(CardButtonStyle())
                
                DescriptionView(media: media, programComposition: programComposition)
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
        
        private var title: String {
            if let channel = channel {
                return currentProgram?.title ?? channel.title
            }
            else {
                return MediaDescription.title(for: media)
            }
        }
        
        private var subtitle: String? {
            guard let currentProgram = currentProgram else { return nil }
            let remainingTimeInterval = currentProgram.endDate.timeIntervalSince(Date())
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
