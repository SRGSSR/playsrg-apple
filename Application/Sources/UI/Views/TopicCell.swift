//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct TopicCell: View {
    let topic: SRGTopic?
    
    @Environment(\.isSelected) private var isSelected
    
    var body: some View {
        Group {
#if os(tvOS)
            ExpandingCardButton(action: action) {
                MainView(topic: topic)
                    .unredactable()
                    .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
            }
#else
            MainView(topic: topic)
                .redactable()
                .selectionAppearance(when: isSelected && topic != nil)
                .cornerRadius(LayoutStandardViewCornerRadius)
                .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
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
        
        private var imageUrl: URL? {
            return url(for: topic?.image, size: .small)
        }
        
        var body: some View {
            ZStack {
                ImageView(url: imageUrl)
                    .aspectRatio(TopicCellSize.aspectRatio, contentMode: .fit)
                    .background(Color.placeholder)
                Color.srgGray23
                    .opacity(0.3)
                Text(topic?.title ?? "")
                    .srgFont(.button)
                    .minimumScaleFactor(0.8)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(10)
            }
        }
    }
}

// MARK: Accessibility

private extension TopicCell {
    var accessibilityLabel: String? {
        return topic?.title
    }
    
    var accessibilityHint: String? {
        return PlaySRGAccessibilityLocalizedString("Opens topic details.", comment: "Show cell hint")
    }
}

// MARK: Size

final class TopicCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    private static let defaultItemWidth: CGFloat = constant(iOS: 150, tvOS: 300)
    
    @objc static func swimlane() -> NSCollectionLayoutSize {
        return swimlane(itemWidth: defaultItemWidth)
    }
    
    @objc static func swimlane(itemWidth: CGFloat) -> NSCollectionLayoutSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio, 0)
    }
    
    @objc static func grid(layoutWidth: CGFloat, spacing: CGFloat) -> NSCollectionLayoutSize {
        return LayoutGridCellSize(defaultItemWidth, aspectRatio, 0, layoutWidth, spacing, 2)
    }
}

// MARK: Preview

struct TopicCell_Previews: PreviewProvider {
    private static let size = TopicCellSize.swimlane().previewSize
    
    static var previews: some View {
        TopicCell(topic: Mock.topic())
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
