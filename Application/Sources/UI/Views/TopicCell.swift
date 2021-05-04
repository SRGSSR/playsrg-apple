//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct TopicCell: View {
    let topic: SRGTopic?
    
    var body: some View {
        Group {
            #if os(tvOS)
            ExpandingCardButton(action: action) {
                MainView(topic: topic)
                    .unredactable()
                    .accessibilityElement()
                    .accessibilityOptionalLabel(topic?.title)
                    .accessibility(addTraits: .isButton)
            }
            #else
            MainView(topic: topic)
                .redactable()
                .cornerRadius(LayoutStandardViewCornerRadius)
                .accessibilityElement()
                .accessibilityOptionalLabel(topic?.title)
            #endif
        }
        .redactedIfNil(topic)
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
                Color(.play_cardGrayBackground)
                    .opacity(0.3)
                Text(topic?.title ?? "")
                    .srgFont(.button)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding(TopicCellSize.padding)
            }
        }
    }
}

class TopicCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    fileprivate static let padding: CGFloat = 10
    
    private static let defaultItemWidth: CGFloat = constant(iOS: 150, tvOS: 250)
    
    @objc static func swimlane() -> NSCollectionLayoutSize {
        return swimlane(itemWidth: defaultItemWidth)
    }
    
    @objc static func swimlane(itemWidth: CGFloat) -> NSCollectionLayoutSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio, 0)
    }
}

struct TopicCell_Previews: PreviewProvider {
    static private let size = TopicCellSize.swimlane().previewSize
    
    static var previews: some View {
        TopicCell(topic: Mock.topic())
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
