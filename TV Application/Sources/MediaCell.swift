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
        
        var body: some View {
            Text(MediaDescription.title(for: media))
                .srgFont(.regular, size: .subtitle)
                .lineLimit(2)
            Text(MediaDescription.subtitle(for: media))
                .srgFont(.regular, size: .caption)
                .lineLimit(1)
        }
    }
    
    let media: SRGMedia?
    
    @State private var isPresented = false
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
                    MediaVisual(media: media, scale: .small, contentMode: .fit) {
                        Rectangle().fill(Color.clear)
                    }.frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                }
                .buttonStyle(CardButtonStyle())
                
                DescriptionView(media: media)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .opacity(isFocused ? 1 : 0.5)
                    .scaleEffect(isFocused ? 1.1 : 1)
                    .offset(x: 0, y: isFocused ? 10 : 0)
            }
            .onPreferenceChange(FocusedKey.self) { value in
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
