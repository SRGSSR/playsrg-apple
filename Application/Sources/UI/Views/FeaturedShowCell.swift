//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

protocol FeaturedShowCellData {
    var title: String? { get }
    var subtitle: String? { get }
    var availability: String? { get }
    var imageUrl: URL? { get }
    var redactionReason: RedactionReasons { get }
    
    #if os(tvOS)
    func action()
    #endif
}

// FIXME: The `Layout.h` size for a featured show cell is not tall enough if a badge is displayed, see
//        Xcode previews on iOS. Either move the badge or tweak the values
struct FeaturedShowCell: View {
    enum Layout {
        case hero
        case highlight
    }
    
    let data: FeaturedShowCellData
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
        CardButton(action: data.action) {
            HStack(spacing: 0) {
                ImageView(url: data.imageUrl)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .layoutPriority(1)
                DescriptionView(data: data, alignment: descriptionAlignment)
            }
            .background(Color(.play_cardGrayBackground))
            .cornerRadius(LayoutStandardViewCornerRadius)
            .redacted(reason: data.redactionReason)
            .accessibilityElement()
            .accessibilityLabel(data.title ?? "")
            .accessibility(addTraits: .isButton)
        }
        #else
        Stack(direction: direction, spacing: 0) {
            ImageView(url: data.imageUrl)
                .aspectRatio(16 / 9, contentMode: .fit)
                .layoutPriority(1)
            DescriptionView(data: data, alignment: descriptionAlignment)
        }
        .background(Color(.play_cardGrayBackground))
        .cornerRadius(LayoutStandardViewCornerRadius)
        .redacted(reason: data.redactionReason)
        .accessibilityElement()
        .accessibilityLabel(data.title ?? "")
        #endif
    }
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        enum Alignment {
            case leading
            case center
        }
        
        let data: FeaturedShowCellData
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
                Text(data.title ?? "")
                    .srgFont(.H2)
                    .lineLimit(1)
                    .multilineTextAlignment(textAlignment)
                if let subtitle = data.subtitle {
                    Text(subtitle)
                        .srgFont(.body)
                        .lineLimit(3)
                        .multilineTextAlignment(textAlignment)
                        .opacity(0.8)
                }
                
                if let availability = data.availability {
                    Badge(text: availability, color: Color(.play_gray))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
            .foregroundColor(.white)
        }
    }
}

extension FeaturedShowCell {
    struct Data: FeaturedShowCellData {
        let show: SRGShow?
        
        var title: String? {
            return show?.title
        }
        
        var subtitle: String? {
            return show?.lead
        }
        
        var availability: String? {
            return show?.broadcastInformation?.message
        }
        
        var imageUrl: URL? {
            return show?.imageURL(for: .width, withValue: SizeForImageScale(.large).width, type: .default)
        }
        
        var redactionReason: RedactionReasons {
            return show == nil ? .placeholder : .init()
        }
        
        #if os(tvOS)
        func action() {
            if let show = show {
                navigateToShow(show)
            }
        }
        #endif
    }
    
    init(show: SRGShow?, layout: Layout) {
        self.init(data: Data(show: show), layout: layout)
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
    private struct MockData: FeaturedShowCellData {
        var title: String? {
            return "19h30"
        }
        
        var subtitle: String? {
            return "Le journal du soir de la RTS\nUn condensé de l'actualité du jour"
        }
        
        var availability: String? {
            return "Prochaine diffusion: Ce soir à 19h30"
        }
        
        var imageUrl: URL? {
            return Bundle.main.url(forResource: "show_19h30", withExtension: "jpg", subdirectory: "Images")
        }
        
        var redactionReason: RedactionReasons {
            return .init()
        }
        
        #if os(tvOS)
        func action() {}
        #endif
    }
    
    static var previews: some View {
        #if os(tvOS)
        FeaturedShowCell(data: MockData(), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 1800, horizontalSizeClass: .regular)
            .previewDisplayName("Cell (hero)")
        
        FeaturedShowCell(data: MockData(), layout: .highlight)
            .previewLayout(for: .hero, layoutWidth: 1800, horizontalSizeClass: .regular)
            .previewDisplayName("Cell (highlight)")
        #else
        FeaturedShowCell(data: MockData(), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
            .previewDisplayName("Cell (hero, regular)")
        
        FeaturedShowCell(data: MockData(), layout: .hero)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
            .previewDisplayName("Cell (hero, compact)")
        
        FeaturedShowCell(data: MockData(), layout: .highlight)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .regular)
            .environment(\.horizontalSizeClass, .regular)
            .previewDisplayName("Cell (highlight, regular)")
        
        FeaturedShowCell(data: MockData(), layout: .highlight)
            .previewLayout(for: .hero, layoutWidth: 800, horizontalSizeClass: .compact)
            .environment(\.horizontalSizeClass, .compact)
            .previewDisplayName("Cell (compact)")
        #endif
    }
}
