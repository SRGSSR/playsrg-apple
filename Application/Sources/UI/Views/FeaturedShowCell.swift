//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// FIXME: The `Layout.h` size for a featured show cell is not tall enough if a badge is displayed, see
//        Xcode previews on iOS. Either move the badge or tweak the values
struct FeaturedShowCell: View {
    enum Layout {
        case hero
        case highlight
    }
    
    let show: SRGShow?
    let layout: Layout
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var direction: StackDirection {
        return horizontalSizeClass == .compact ? .vertical : .horizontal
    }
    #endif
    
    private var descriptionAlignment: DescriptionView.Alignment {
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
                ImageView(url: show?.imageUrl(for: .large))
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .layoutPriority(1)
                DescriptionView(show: show, alignment: descriptionAlignment)
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
            DescriptionView(show: show, alignment: descriptionAlignment)
        }
        .background(Color(.play_cardGrayBackground))
        .cornerRadius(LayoutStandardViewCornerRadius)
        .accessibilityElement()
        .accessibilityOptionalLabel(show?.title)
        .redactedIfNil(show)
        #endif
    }
    
    #if os(tvOS)
    func action() {
        if let show = show {
            navigateToShow(show)
        }
    }
    #endif
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        enum Alignment {
            case leading
            case center
        }
        
        let show: SRGShow?
        let alignment: Alignment
        
        private var stackAlignment: HorizontalAlignment {
            return alignment == .leading ? .leading : .center
        }
        
        private var frameAlignment: SwiftUI.Alignment {
            return alignment == .leading ? .leading : .center
        }
        
        private var textAlignment: TextAlignment {
            return alignment == .leading ? .leading : .center
        }
        
        var body: some View {
            VStack(alignment: stackAlignment) {
                Text(show?.title ?? "")
                    .srgFont(.H2)
                    .lineLimit(1)
                    .multilineTextAlignment(textAlignment)
                if let lead = show?.lead {
                    Text(lead)
                        .srgFont(.body)
                        .lineLimit(3)
                        .multilineTextAlignment(textAlignment)
                        .opacity(0.8)
                }
                
                if let message = show?.broadcastInformation?.message {
                    Badge(text: message, color: Color(.play_gray))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
            .foregroundColor(.white)
        }
    }
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
    static var previews: some View {
        #if os(tvOS)
        FeaturedShowCell(show: Mock.show(), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 1800, horizontalSizeClass: .regular)
        
        FeaturedShowCell(show: Mock.show(), layout: .highlight)
            .previewLayout(for: .hero, layoutWidth: 1800, horizontalSizeClass: .regular)
        #else
        FeaturedShowCell(show: Mock.show(), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
        
        FeaturedShowCell(show: Mock.show(), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        
        FeaturedShowCell(show: Mock.show(), layout: .highlight)
            .previewLayout(for: .highlight, layoutWidth: 800, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
        
        FeaturedShowCell(show: Mock.show(), layout: .highlight)
            .previewLayout(for: .highlight, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        #endif
    }
}
