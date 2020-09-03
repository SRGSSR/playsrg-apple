//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct DurationLabel: View {
    let media: SRGMedia?
    
    private var duration: String? {
        guard let media = media else { return nil }
        return DurationFormatters.minutes(for: media.duration / 1000)
    }
    
    var body: some View {
        if let duration = duration {
            Text(duration)
                .font(.caption)
                .foregroundColor(.white)
                .padding([.top, .bottom], 5)
                .padding([.leading, .trailing], 8)
                .background(Color.init(white: 0, opacity: 0.5))
                .cornerRadius(4)
                .padding([.trailing, .bottom], 8)
        }
    }
}

struct MediaCell: View {
    let media: SRGMedia?
    
    @State private var isPresented = false
    
    private var title: String {
        guard let media = media else { return String(repeating: " ", count: .random(in: 15..<30)) }
        return media.title
    }
    
    private var imageUrl: URL? {
        return media?.imageURL(for: .width, withValue: 200, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    private func play() {
        if media != nil {
            isPresented.toggle()
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Button(action: play) {
                    ImageView(url: imageUrl)
                        .overlay(DurationLabel(media: media), alignment: .bottomTrailing)
                        .whenRedacted { $0.hidden() }
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                }
                .buttonStyle(CardButtonStyle())
                
                Text(title)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            .redacted(reason: redactionReason)
            .fullScreenCover(isPresented: $isPresented, content: {
                PlayerView(media: media!)
            })
        }
    }
}
