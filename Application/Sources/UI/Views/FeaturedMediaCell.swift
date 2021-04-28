//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// TODO: Merge with FeaturedShowCell
struct FeaturedMediaCell: View {
    enum Layout {
        case hero
        case highlight
    }
    
    let media: SRGMedia?
    let layout: Layout
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var direction: StackDirection {
        return horizontalSizeClass == .compact ? .vertical : .horizontal
    }
    #endif
    
    private var descriptionAlignment: FeaturedDescriptionView.Alignment {
        if layout == .hero {
            #if os(iOS)
            return  horizontalSizeClass == .regular ? .center : .leading
            #else
            return .center
            #endif
        }
        else {
            return .leading
        }
    }
    
    var body: some View {
        #if os(tvOS)
        ExpandingCardButton(action: action) {
            HStack(spacing: 0) {
                MediaVisualView(media: media, scale: .large)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .layoutPriority(1)
                FeaturedDescriptionView(media: media, alignment: descriptionAlignment)
            }
            .background(Color(.play_cardGrayBackground))
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityOptionalLabel(MediaDescription.accessibilityLabel(for: media))
            .accessibility(addTraits: .isButton)
            .redactedIfNil(media)
        }
        #else
        Stack(direction: direction, spacing: 0) {
            MediaVisualView(media: media, scale: .large)
                .aspectRatio(16 / 9, contentMode: .fit)
                .layoutPriority(1)
            FeaturedDescriptionView(media: media, alignment: descriptionAlignment)
        }
        .background(Color(.play_cardGrayBackground))
        .cornerRadius(LayoutStandardViewCornerRadius)
        .accessibilityElement()
        .accessibilityOptionalLabel(MediaDescription.accessibilityLabel(for: media))
        .redactedIfNil(media)
        #endif
    }
    
    #if os(tvOS)
    private func action() {
        if let media = media {
            navigateToMedia(media)
        }
    }
    #endif
}

private extension View {
    static private func size(for layout: FeaturedMediaCell.Layout, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> CGSize {
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
    
    func previewLayout(for layout: FeaturedMediaCell.Layout, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> some View {
        let size = Self.size(for: layout, layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
        return self.previewLayout(.fixed(width: size.width, height: size.height))
            .horizontalSizeClass(horizontalSizeClass)
    }
}

struct FeaturedMediaCell_Previews: PreviewProvider {
    static var previews: some View {
        #if os(tvOS)
        FeaturedMediaCell(media: Mock.media(), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 1800, horizontalSizeClass: .regular)
        
        FeaturedMediaCell(media: Mock.media(), layout: .highlight)
            .previewLayout(for: .hero, layoutWidth: 1800, horizontalSizeClass: .regular)
        #else
        FeaturedMediaCell(media: Mock.media(), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
        
        FeaturedMediaCell(media: Mock.media(), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        
        FeaturedMediaCell(media: Mock.media(), layout: .highlight)
            .previewLayout(for: .highlight, layoutWidth: 800, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
        
        FeaturedMediaCell(media: Mock.media(), layout: .highlight)
            .previewLayout(for: .highlight, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        #endif
    }
}
