//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct MediaCell: View {
    let media: SRGMedia?
    let action: (() -> Void)?
    
    @State private var isFocused: Bool = false
    
    init(media: SRGMedia?, action: (() -> Void)? = nil) {
        self.media = media
        self.action = action
    }
        
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Button(action: action ?? {
                    if let media = media,
                       let topViewController = UIApplication.shared.windows.first?.topViewController {
                        let hostController = UIHostingController(rootView: MediaDetailView(media: media))
                        topViewController.present(hostController, animated: true, completion: nil)
                    }
                }) {
                    MediaVisual(media: media, scale: .small, contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                        .reportFocusChanges()
                }
                .buttonStyle(CardButtonStyle())
                .onFocusChange { isFocused = $0 }
                
                DescriptionView(media: media)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .opacity(isFocused ? 1 : 0.5)
                    .offset(x: 0, y: isFocused ? 10 : 0)
                    .scaleEffect(isFocused ? 1.1 : 1, anchor: .top)
                    .animation(.easeInOut(duration: 0.2))
            }
            .redacted(reason: redactionReason)
            .animation(nil)
        }
    }
}

extension MediaCell {
    private struct DescriptionView: View {
        let media: SRGMedia?
        
        var body: some View {
            Text(MediaDescription.title(for: media))
                .srgFont(.medium, size: .subtitle)
                .lineLimit(2)
            Text(MediaDescription.subtitle(for: media))
                .srgFont(.light, size: .subtitle)
                .lineLimit(2)
        }
    }
}
