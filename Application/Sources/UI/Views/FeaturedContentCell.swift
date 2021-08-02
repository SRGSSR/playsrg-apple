//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

enum FeaturedContentLayout {
    case hero
    case highlight
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
            return layout == .hero ? .center : .leading
        }
    }
    
    private var detailed: Bool {
        #if os(iOS)
        return layout == .highlight || horizontalSizeClass == .regular
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
                    .background(Color.white.opacity(0.1))
                    .layoutPriority(1)
                FeaturedDescriptionView(content: content, alignment: descriptionAlignment, detailed: detailed)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
            }
            .background(Color.srgGray23)
            .redactable()
            .selectionAppearance(when: isSelected)
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

final class FeaturedContentCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    @objc static func hero(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if horizontalSizeClass == .compact {
            return LayoutSwimlaneCellSize(layoutWidth, aspectRatio, 100)
        }
        else {
            return LayoutFractionedCellSize(layoutWidth, aspectRatio, 0.6)
        }
    }
    
    @objc static func highlight(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if horizontalSizeClass == .compact {
            return LayoutSwimlaneCellSize(layoutWidth, aspectRatio, 145)
        }
        else {
            return LayoutFractionedCellSize(layoutWidth, aspectRatio, 0.4)
        }
    }
}

// MARK: Preview

private extension View {
    private func horizontalSizeClass(_ sizeClass: UIUserInterfaceSizeClass) -> some View {
        #if os(iOS)
        return self.environment(\.horizontalSizeClass, UserInterfaceSizeClass(sizeClass))
        #else
        return self
        #endif
    }
    
    func previewLayout(for layout: FeaturedContentLayout, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> some View {
        let size: CGSize = {
            if layout == .hero {
                return FeaturedContentCellSize.hero(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass).previewSize
            }
            else {
                return FeaturedContentCellSize.highlight(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass).previewSize
            }
        }()
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
        
        FeaturedContentCell(media: Mock.media(kind), label: label, layout: .highlight)
            .previewLayout(for: .highlight, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
        #endif
    }
}
