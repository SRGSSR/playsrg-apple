//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

enum FeaturedContentLayout {
    case headline
    case element
}

struct FeaturedContentCell<Content: FeaturedContent>: View {
    let content: Content
    let layout: FeaturedContentLayout
    
    @Environment(\.isSelected) private var isSelected
    
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif
    
    private var direction: StackDirection {
#if os(iOS)
        if horizontalSizeClass == .compact {
            return .vertical
        }
#endif
        return .horizontal
    }
    
    private var horizontalPadding: CGFloat {
#if os(iOS)
        if horizontalSizeClass == .compact {
            return 8
        }
#endif
        return constant(iOS: 54, tvOS: 50)
    }
    
    private var verticalPadding: CGFloat {
#if os(iOS)
        if horizontalSizeClass == .compact {
            return 12
        }
#endif
        return constant(iOS: 16, tvOS: 16)
    }
    
    private var descriptionAlignment: FeaturedDescriptionView<Content>.Alignment {
        if direction == .vertical {
            return .topLeading
        }
        else {
            return layout == .headline ? .center : .leading
        }
    }
    
    private var detailed: Bool {
#if os(iOS)
        return horizontalSizeClass == .regular
#else
        return true
#endif
    }
    
    var body: some View {
        Group {
#if os(tvOS)
            ExpandingCardButton(action: content.action) {
                HStack(spacing: 0) {
                    content.visualView()
                        .aspectRatio(FeaturedContentCellSize.aspectRatio, contentMode: .fit)
                        .layoutPriority(1)
                    FeaturedDescriptionView(content: content, alignment: descriptionAlignment, detailed: detailed)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, verticalPadding)
                }
                .background(Color.srgGray23)
                .cornerRadius(LayoutStandardViewCornerRadius)
                .unredactable()
                .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
            }
#else
            Stack(direction: direction, spacing: 0) {
                content.visualView()
                    .aspectRatio(FeaturedContentCellSize.aspectRatio, contentMode: .fit)
                    .layoutPriority(1)
                FeaturedDescriptionView(content: content, alignment: descriptionAlignment, detailed: detailed)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
            }
            .background(Color.srgGray23)
            .redactable()
            .selectionAppearance(when: isSelected && !content.isPlaceholder)
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
#endif
        }
        .redacted(reason: content.isPlaceholder ? .placeholder : .init())
    }
}

// MARK: Initializers

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

// MARK: Accessibility

private extension FeaturedContentCell {
    var accessibilityLabel: String? {
        return content.accessibilityLabel
    }
    
    var accessibilityHint: String? {
        return content.accessibilityHint
    }
}

// MARK: Size

enum FeaturedContentCellSize {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    static func headline(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if horizontalSizeClass == .compact {
            return LayoutSwimlaneCellSize(layoutWidth, aspectRatio, 100)
        }
        else {
            return LayoutFractionedCellSize(layoutWidth, aspectRatio, 0.6)
        }
    }
    
    static func element(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if horizontalSizeClass == .compact {
            return LayoutSwimlaneCellSize(layoutWidth, aspectRatio, 80)
        }
        else {
            return LayoutFractionedCellSize(layoutWidth, aspectRatio, 0.4)
        }
    }
}

// MARK: Preview

private extension View {
    func previewLayout(for layout: FeaturedContentLayout, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> some View {
        let size: CGSize = {
            if layout == .headline {
                return FeaturedContentCellSize.headline(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass).previewSize
            }
            else {
                return FeaturedContentCellSize.element(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass).previewSize
            }
        }()
        return previewLayout(.fixed(width: size.width, height: size.height))
            .horizontalSizeClass(horizontalSizeClass)
    }
}

struct FeaturedContentCell_Previews: PreviewProvider {
    private static let kind: Mock.Media = .standard
    private static let label = "New"
    
    static var previews: some View {
#if os(tvOS)
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .headline)
            .previewLayout(for: .headline, layoutWidth: 1800, horizontalSizeClass: .regular)
        
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .element)
            .previewLayout(for: .headline, layoutWidth: 1800, horizontalSizeClass: .regular)
#else
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .headline)
            .previewLayout(for: .headline, layoutWidth: 1200, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
        
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .headline)
            .previewLayout(for: .headline, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .element)
            .previewLayout(for: .element, layoutWidth: 1200, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
        
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .element)
            .previewLayout(for: .element, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        #endif
    }
}
