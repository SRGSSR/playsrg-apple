//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct TopicCell: View {
    let topic: SRGTopic?
    
    var body: some View {
        #if os(tvOS)
        MainView(topic: topic)
            .cardButton {
                if let topic = topic {
                    navigateToTopic(topic)
                }
            }
        #else
        MainView(topic: topic)
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
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.4))
                Text(title)
                    .srgFont(.overline)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .redacted(reason: redactionReason)
            .accessibilityElement()
            .accessibilityLabel(topic?.title ?? "")
        }
    }
}
