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
        ExpandingCardButton(action: action) {
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
    private func action() {
        if let topic = topic {
            navigateToTopic(topic)
        }
    }
    #endif
    
    /// Behavior: h-exp, v-exp
    private struct MainView: View {
        let topic: SRGTopic?
        
        var body: some View {
            ZStack {
                ImageView(url: topic?.imageUrl(for: .small))
                    .aspectRatio(TopicCellSize.aspectRatio, contentMode: .fit)
                Color(white: 0, opacity: 0.2)
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

class TopicCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    #if os(tvOS)
    private static let defaultItemWidth: CGFloat = 250
    #else
    private static let defaultItemWidth: CGFloat = 150
    #endif
    
    @objc static func swimlane() -> CGSize {
        return swimlane(itemWidth: defaultItemWidth)
    }
    
    @objc static func swimlane(itemWidth: CGFloat) -> CGSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio, 0)
    }
}

struct TopicCell_Previews: PreviewProvider {
    static private let size = TopicCellSize.swimlane()
    
    static var previews: some View {
        TopicCell(topic: Mock.topic())
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
