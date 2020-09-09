//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct TopicCell: View {
    private struct Appearance {
        let shadowRadius: CGFloat
        let scale: CGFloat
    }
    
    let topic: SRGTopic?
    
    @Environment(\.isFocused) private var isFocused: Bool
    @Environment(\.isPressed) private var isPressed: Bool
    
    private var title: String {
        return topic?.title ?? ""
    }
    
    private var imageUrl: URL? {
        return topic?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return topic == nil ? .placeholder : .init()
    }
    
    private var appearance: Appearance {
        if isPressed {
            return Appearance(shadowRadius: 10, scale: 1.05)
        }
        else if isFocused {
            return Appearance(shadowRadius: 20, scale: 1.1)
        }
        else {
            return Appearance(shadowRadius: 0, scale: 1)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ImageView(url: imageUrl)
                    .whenRedacted { $0.hidden() }
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.4))
                Text(title)
                    .srgFont(.medium, size: .subtitle)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .cornerRadius(12)
            .shadow(radius: appearance.shadowRadius)
            .scaleEffect(appearance.scale)
            .redacted(reason: redactionReason)
            .animation(.default)
        }
    }
}
