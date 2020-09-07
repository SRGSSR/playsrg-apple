//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct HeroMediaCell: View {
    private struct DescriptionView: View {
        let media: SRGMedia?
        
        var body: some View {
            VStack {
                Text(MediaDescription.title(for: media))
                    .srgFont(.bold, size: .title)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(MediaDescription.subtitle(for: media))
                    .srgFont(.regular, size: .headline)
                    .lineLimit(1)
            }
            .foregroundColor(.white)
        }
    }
    
    let media: SRGMedia?
    
    @State private var isPresented = false
    
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
            Button(action: play) {
                ZStack {
                    MediaVisual(media: media, scale: .large, contentMode: .fill) {
                        Rectangle()
                            .fill(Color(white: 0, opacity: 0.4))
                        DescriptionView(media: media)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .padding(60)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .buttonStyle(CardButtonStyle())
            .redacted(reason: redactionReason)
            .fullScreenCover(isPresented: $isPresented) {
                PlayerView(media: media!)
            }
        }
    }
}
