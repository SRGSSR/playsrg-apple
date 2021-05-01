//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

enum FeaturedContentLayout {
    case hero
    case highlight
}

struct FeaturedContentCell<Content: FeaturedContent>: View {
    let content: Content
    let layout: FeaturedContentLayout
    
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
    
    private var descriptionAlignment: FeaturedDescriptionView<Content>.Alignment {
        if direction == .vertical {
            return .topLeading
        }
        else {
            return layout == .hero ? .center : .leading
        }
    }
    
    var body: some View {
        Group {
            #if os(tvOS)
            ExpandingCardButton(action: content.action) {
                HStack(spacing: 0) {
                    content.visualView()
                        .aspectRatio(FeaturedContentCellSize.aspectRatio, contentMode: .fit)
                        .layoutPriority(1)
                    FeaturedDescriptionView(content: content, alignment: descriptionAlignment)
                }
                .background(Color(.play_cardGrayBackground))
                .cornerRadius(LayoutStandardViewCornerRadius)
                .unredactable()
                .accessibilityElement()
                .accessibilityOptionalLabel(content.accessibilityLabel)
                .accessibility(addTraits: .isButton)
            }
            #else
            Stack(direction: direction, spacing: 0) {
                content.visualView()
                    .aspectRatio(FeaturedContentCellSize.aspectRatio, contentMode: .fit)
                    .layoutPriority(1)
                FeaturedDescriptionView(content: content, alignment: descriptionAlignment)
            }
            .background(Color(.play_cardGrayBackground))
            .redactable()
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityOptionalLabel(content.accessibilityLabel)
            #endif
        }
        .redacted(reason: content.isPlaceholder ? .placeholder : .init())
    }
}

extension FeaturedContentCell where Content == FeaturedMediaContent {
    init(media: SRGMedia?, label: String? = nil, layout: FeaturedContentLayout) {
        self.init(content: FeaturedMediaContent(media: media, label: label), layout: layout)
    }
}

extension FeaturedContentCell where Content == FeaturedShowContent {
    init(show: SRGShow?, label: String? = nil, layout: FeaturedContentLayout) {
        self.init(content: FeaturedShowContent(show: show, label: label), layout: layout)
    }
}

class FeaturedContentCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    @objc static func hero(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> CGSize {
        if horizontalSizeClass == .compact {
            return LayoutSwimlaneCellSize(0.9 * layoutWidth, aspectRatio, 89);
        }
        else {
            return LayoutFractionedCellSize(0.9 * layoutWidth, aspectRatio, 0.6);
        }
    }
    
    @objc static func highlight(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> CGSize {
        if horizontalSizeClass == .compact {
            return LayoutSwimlaneCellSize(layoutWidth, aspectRatio, 89);
        }
        else {
            return LayoutFractionedCellSize(layoutWidth, aspectRatio, 0.4);
        }
    }
}

private extension View {
    private func horizontalSizeClass(_ sizeClass: UIUserInterfaceSizeClass) -> some View {
        #if os(iOS)
        return self.environment(\.horizontalSizeClass, UserInterfaceSizeClass(sizeClass))
        #else
        return self
        #endif
    }
    
    func previewLayout(for layout: FeaturedContentLayout, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> some View {
        let size = (layout == .hero) ? FeaturedContentCellSize.hero(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass) : FeaturedContentCellSize.highlight(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
        return self.previewLayout(.fixed(width: size.width, height: size.height))
            .horizontalSizeClass(horizontalSizeClass)
    }
}

struct FeaturedContentCell_Previews: PreviewProvider {
    static let kind: Mock.Media = .standard
    static let label = "New"
    
    static var previews: some View {
        #if os(tvOS)
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 1800, horizontalSizeClass: .regular)
        
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .highlight)
            .previewLayout(for: .hero, layoutWidth: 1800, horizontalSizeClass: .regular)
        #else
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 1200, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
        
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .highlight)
            .previewLayout(for: .highlight, layoutWidth: 1200, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
        
        FeaturedContentCell(media: Mock.media(kind), layout: .highlight)
            .previewLayout(for: .highlight, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        #endif
    }
}
