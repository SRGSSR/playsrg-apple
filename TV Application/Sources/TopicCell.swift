//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct TopicCell: View {
    let topic: SRGTopic?
    
    @Environment(\.isFocused) private var isFocused: Bool
    
    private var title: String {
        return topic?.title ?? ""
    }
    
    private var imageUrl: URL? {
        return topic?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return topic == nil ? .placeholder : .init()
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
            .shadow(radius: isFocused ? 20 : 0)
            .scaleEffect(isFocused ? 1.1 : 1)
            .redacted(reason: redactionReason)
            .animation(.default)
        }
    }
}
