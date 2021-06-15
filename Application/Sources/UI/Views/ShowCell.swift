//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct ShowCell: View {
    let show: SRGShow?
    let direction: StackDirection
    let hasSubscriptionButton: Bool
    
    init(show: SRGShow?, direction: StackDirection = .vertical, hasSubscriptionButton: Bool = false) {
        self.show = show
        self.direction = direction
        self.hasSubscriptionButton = hasSubscriptionButton
    }
    
    var body: some View {
        Group {
            #if os(tvOS)
            LabeledCardButton(aspectRatio: ShowCellSize.aspectRatio, action: action) {
                ImageView(url: show?.imageUrl(for: .small))
                    .unredactable()
                    .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
            } label: {
                DescriptionView(show: show)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, ShowCellSize.verticalPadding)
            }
            #else
            Stack(direction: direction, spacing: 0) {
                ImageView(url: show?.imageUrl(for: .small))
                    .aspectRatio(ShowCellSize.aspectRatio, contentMode: .fit)
                    .background(Color.white.opacity(0.1))
                DescriptionView(show: show)
                    .padding(.horizontal, ShowCellSize.horizontalPadding)
                    .padding(.vertical, ShowCellSize.verticalPadding)
                if self.hasSubscriptionButton {
                    SubscriptionButton(show: show)
                        .padding(.horizontal, ShowCellSize.horizontalPadding)
                        .padding(.vertical, ShowCellSize.verticalPadding)
                }
            }
            .background(Color.srgGray2)
            .redactable()
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
            .frame(maxHeight: .infinity, alignment: .top)
            #endif
        }
        .redactedIfNil(show)
    }
    
    #if os(tvOS)
    private func action() {
        if let show = show {
            navigateToShow(show)
        }
    }
    #endif
    
    /// Behavior: h-exp, v-hug
    private struct DescriptionView: View {
        let show: SRGShow?
        
        var body: some View {
            Text(show?.title ?? "")
                .srgFont(.H4)
                .foregroundColor(.srgGray5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: Accessibility

private extension ShowCell {
    var accessibilityLabel: String? {
        return show?.title
    }
    
    var accessibilityHint: String? {
        return PlaySRGAccessibilityLocalizedString("Opens show details.", "Show cell hint")
    }
}

// MARK: Size

class ShowCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    fileprivate static let horizontalPadding: CGFloat = constant(iOS: 10, tvOS: 0)
    fileprivate static let verticalPadding: CGFloat = constant(iOS: 5, tvOS: 7)
    
    private static let defaultItemWidth: CGFloat = constant(iOS: 210, tvOS: 375)
    private static let heightOffset: CGFloat = constant(iOS: 32, tvOS: 45)
    
    @objc static func swimlane() -> NSCollectionLayoutSize {
        return swimlane(itemWidth: defaultItemWidth)
    }
    
    @objc static func swimlane(itemWidth: CGFloat) -> NSCollectionLayoutSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio, heightOffset)
    }
    
    @objc static func grid(layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> NSCollectionLayoutSize {
        return grid(approximateItemWidth: defaultItemWidth, layoutWidth: layoutWidth, spacing: spacing, minimumNumberOfColumns: minimumNumberOfColumns)
    }
    
    @objc static func grid(approximateItemWidth: CGFloat, layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> NSCollectionLayoutSize {
        return LayoutGridCellSize(approximateItemWidth, aspectRatio, heightOffset, layoutWidth, spacing, minimumNumberOfColumns)
    }
    
    @objc static func fullWidth() -> NSCollectionLayoutSize {
        return fullWidth(itemHeight: constant(iOS: 84, tvOS: 120))
    }
    
    @objc static func fullWidth(itemHeight: CGFloat) -> NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight))
    }
}

// MARK: Preview

struct ShowCell_Previews: PreviewProvider {
    static private let verticalLayoutSize = ShowCellSize.swimlane().previewSize
    static private let horizontalLayoutSize = ShowCellSize.fullWidth().previewSize
    
    static var previews: some View {
        ShowCell(show: Mock.show(.standard))
            .previewLayout(.fixed(width: verticalLayoutSize.width, height: verticalLayoutSize.height))
    
        Group {
            ShowCell(show: Mock.show(.standard), direction: .horizontal)
                .previewLayout(.fixed(width: horizontalLayoutSize.width, height: horizontalLayoutSize.height))
            ShowCell(show: Mock.show(.standard), direction: .horizontal, hasSubscriptionButton: true)
                .previewLayout(.fixed(width: horizontalLayoutSize.width, height: horizontalLayoutSize.height))
        }
    }
}
