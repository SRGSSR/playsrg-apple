//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// TODO: Merge with FeaturedMediaCell
struct FeaturedShowCell: View {
    enum Layout {
        case hero
        case highlight
    }
    
    let show: SRGShow?
    let layout: Layout
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    private var direction: StackDirection {
        #if os(iOS)
        return horizontalSizeClass == .compact ? .vertical : .horizontal
        #else
        return .horizontal
        #endif
    }
    
    private var descriptionAlignment: FeaturedDescriptionView.Alignment {
        if direction == .vertical {
            return .topLeading
        }
        else {
            return layout == .hero ? .center : .leading
        }
    }
    
    var body: some View {
        #if os(tvOS)
        ExpandingCardButton(action: action) {
            HStack(spacing: 0) {
                ImageView(url: show?.imageUrl(for: .large))
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .layoutPriority(1)
                FeaturedDescriptionView(show: show, alignment: descriptionAlignment)
            }
            .background(Color(.play_cardGrayBackground))
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityOptionalLabel(show?.title)
            .accessibility(addTraits: .isButton)
            .redactedIfNil(show)
        }
        #else
        Stack(direction: direction, spacing: 0) {
            ImageView(url: show?.imageUrl(for: .large))
                .aspectRatio(16 / 9, contentMode: .fit)
                .layoutPriority(1)
            FeaturedDescriptionView(show: show, alignment: descriptionAlignment)
        }
        .background(Color(.play_cardGrayBackground))
        .cornerRadius(LayoutStandardViewCornerRadius)
        .accessibilityElement()
        .accessibilityOptionalLabel(show?.title)
        .redactedIfNil(show)
        #endif
    }
    
    #if os(tvOS)
    private func action() {
        if let show = show {
            navigateToShow(show)
        }
    }
    #endif
}

private extension View {
    static private func size(for layout: FeaturedShowCell.Layout, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> CGSize {
        let itemType: LayoutCollectionItemType = (layout == .hero) ? .hero : .highlight
        let width = LayoutCollectionItemFeaturedWidth(layoutWidth, itemType)
        return LayoutCollectionItemSize(width, itemType, horizontalSizeClass)
    }
    
    private func horizontalSizeClass(_ sizeClass: UIUserInterfaceSizeClass) -> some View {
        #if os(iOS)
        return self.environment(\.horizontalSizeClass, UserInterfaceSizeClass(sizeClass))
        #else
        return self
        #endif
    }
    
    func previewLayout(for layout: FeaturedShowCell.Layout, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> some View {
        let size = Self.size(for: layout, layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
        return self.previewLayout(.fixed(width: size.width, height: size.height))
            .horizontalSizeClass(horizontalSizeClass)
    }
}

struct FeaturedShowCell_Previews: PreviewProvider {
    static let kind: Mock.Show = .standard
    
    static var previews: some View {
        #if os(tvOS)
        FeaturedShowCell(show: Mock.show(kind), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 1800, horizontalSizeClass: .regular)
        
        FeaturedShowCell(show: Mock.show(kind), layout: .highlight)
            .previewLayout(for: .hero, layoutWidth: 1800, horizontalSizeClass: .regular)
        #else
        FeaturedShowCell(show: Mock.show(kind), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
        
        FeaturedShowCell(show: Mock.show(kind), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        
        FeaturedShowCell(show: Mock.show(kind), layout: .highlight)
            .previewLayout(for: .highlight, layoutWidth: 800, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
        
        FeaturedShowCell(show: Mock.show(kind), layout: .highlight)
            .previewLayout(for: .highlight, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        #endif
    }
}
