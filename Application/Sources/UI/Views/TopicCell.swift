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
        CardButton(action: action) {
            MainView(topic: topic)
                .accessibilityElement()
                .accessibilityOptionalLabel(topic?.title)
                .accessibility(addTraits: .isButton)
        }
        #else
        MainView(topic: topic)
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityOptionalLabel(topic?.title)
        #endif
    }
    
    #if os(tvOS)
    func action() {
        if let topic = topic {
            navigateToTopic(topic)
        }
    }
    #endif
    
    private struct MainView: View {
        let topic: SRGTopic?
        
        var body: some View {
            ZStack {
                ImageView(url: topic?.imageUrl(for: .small))
                    .aspectRatio(16 / 9, contentMode: .fit)
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.2))
                Text(topic?.title ?? "")
                    .srgFont(.overline)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding(20)
            }
            .redactedIfNil(topic)
        }
    }
}

struct TopicCell_Previews: PreviewProvider {
    static private let size = LayoutTopicCollectionItemSize()
    
    static var previews: some View {
        TopicCell(topic: MockData.topic())
            .previewDisplayName("Cell")
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
