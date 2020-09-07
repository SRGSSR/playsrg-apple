//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct MediaCell: View {
    private struct DescriptionView: View {
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
                    MediaVisual(media: media)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                }
                .buttonStyle(CardButtonStyle())
                
                DescriptionView(media: media)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .scaleEffect(isFocused ? 1.1 : 1)
                    .offset(x: 0, y: isFocused ? 10 : 0)
            }
            .onPreferenceChange(MediaVisual.FocusedKey.self) { value in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFocused = value
                }
            }
            .redacted(reason: redactionReason)
            .fullScreenCover(isPresented: $isPresented) {
                PlayerView(media: media!)
            }
        }
    }
}
