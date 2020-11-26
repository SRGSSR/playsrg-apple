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
    
    @State var programComposition: SRGProgramComposition?
    @State private var channelObserver: Any?
    @State private var date = Date()
    @State private var isFocused: Bool = false
    
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
            VStack(spacing: 10) {
                Button(action: {
                    if let media = media {
                        navigateToMedia(media, play: true)
                    }
                }) {
                    VisualView(media: media, programComposition: programComposition, date: date)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                        .onFocusChange { isFocused = $0 }
                }
                .buttonStyle(CardButtonStyle())
                
                DescriptionView(media: media, programComposition: programComposition, date: date)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .animation(nil)
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
    
    private struct VisualView: View, LiveMediaData {
        let media: SRGMedia?
        let programComposition: SRGProgramComposition?
        let date: Date
        
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
                return channel.play_logo60Image
            }
            else {
                return nil
            }
        }
        
        var body: some View {
            ZStack {
                ImageView(url: imageUrl)
                if let logoImage = logoImage {
                    Rectangle()
                        .fill(Color(white: 0, opacity: 0.6))
                    Image(uiImage: logoImage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding()
                }
                else if let media = media, media.timeAvailability(at: Date()) == .notYetAvailable {
                    Rectangle()
                        .fill(Color(white: 0, opacity: 0.6))
                    Badge(text: NSLocalizedString("Soon", comment: "Short label identifying content which will be available soon."), color: Color(.play_gray))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding([.leading, .top], 8)
                }
                BlockingOverlay(media: media)
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
            VStack(alignment: .leading) {
                if let progress = progress {
                    ProgressBar(value: progress)
                        .frame(maxWidth: .infinity, maxHeight: 8)
                }
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
