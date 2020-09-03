//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct FocusedKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {}
}

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

struct MediaVisualView: View {
    let media: SRGMedia?
    
    @Environment(\.isFocused) var isFocused: Bool
    
    private var imageUrl: URL? {
        return media?.imageURL(for: .width, withValue: 200, type: .default)
    }
    
    var body: some View {
        ImageView(url: imageUrl)
            .background(isFocused ? Color.red : Color.white)
            .preference(key: FocusedKey.self, value: isFocused)
            .overlay(DurationLabel(media: media), alignment: .bottomTrailing)
            .whenRedacted { $0.hidden() }
    }
}

struct MediaDescriptionView: View {
    let media: SRGMedia?
    
    static private func showName(for media: SRGMedia) -> String? {
        guard let show = media.show else { return nil }
        return !media.title.contains(show.title) ? show.title : nil
    }
    
    private var title: String {
        guard let media = media else { return String(repeating: " ", count: .random(in: 15..<30)) }
        return media.title
    }
    
    private var subtitle: String {
        guard let media = media else { return String(repeating: " ", count: .random(in: 20..<30)) }
        if let showName = Self.showName(for: media) {
            return "\(showName) - \(DateFormatters.formattedRelativeDate(for: media.date))"
        }
        else {
            return DateFormatters.formattedRelativeDateAndTime(for: media.date)
        }
    }
    
    var body: some View {
        Text(title)
            .lineLimit(2)
        Text(subtitle)
            .font(.caption)
            .lineLimit(1)
    }
}

struct MediaCell: View {
    let media: SRGMedia?
    
    @State private var isPresented = false
    
    /// Focus is received by the Button, detected in its title view, and bubbled up with preferences so that we
    /// can apply a similar focused appearance to the sibling description view.
    @State private var isFocused = false
    
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
                    MediaVisualView(media: media)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                }
                .buttonStyle(CardButtonStyle())
                
                MediaDescriptionView(media: media)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .scaleEffect(isFocused ? 1.1 : 1)
                    .offset(x: 0, y: isFocused ? 10 : 0)
                    .animation(.easeInOut(duration: 0.2))
            }
            .onPreferenceChange(FocusedKey.self) { value in
                isFocused = value
            }
            .redacted(reason: redactionReason)
            .fullScreenCover(isPresented: $isPresented, content: {
                PlayerView(media: media!)
            })
        }
    }
}
