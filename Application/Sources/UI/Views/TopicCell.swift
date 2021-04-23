//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct TopicCell: View {
    let topic: SRGTopic?
    
    private var accessibilityLabel: String {
        return topic?.title ?? ""
    }
    
    #if os(tvOS)
    private func action() {
        if let topic = topic {
            navigateToTopic(topic)
        }
    }
    #endif
    
    var body: some View {
        #if os(tvOS)
        CardButton(action: action) {
            MainView(topic: topic)
                .accessibilityElement()
                .accessibilityLabel(accessibilityLabel)
                .accessibility(addTraits: .isButton)
        }
        #else
        MainView(topic: topic)
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
        #endif
    }
    
    private struct MainView: View {
        let topic: SRGTopic?
        
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
            ZStack {
                ImageView(url: imageUrl)
                    .aspectRatio(contentMode: .fill)
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.2))
                Text(title)
                    .srgFont(.overline)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding(20)
            }
            .redacted(reason: redactionReason)
        }
    }
}
