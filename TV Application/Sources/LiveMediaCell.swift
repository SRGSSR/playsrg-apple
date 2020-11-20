//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//
import SwiftUI

struct LiveMediaCell: View {
    let media: SRGMedia?
    
    @State var channelObserver: Any?
    @State var programComposition: SRGProgramComposition?
    
    private var title: String {
        if let channel = programComposition?.channel ?? media?.channel {
            if let currentProgram = programComposition?.play_program(at: Date()) {
                return currentProgram.title
            }
            else {
                return channel.title
            }
        }
        else {
            return MediaDescription.title(for: media)
        }
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
        Text(title)
            .onAppear {
                registerForChannelUpdates()
            }
            .onDisappear {
                unregisterChannelUpdates()
            }
    }
}
