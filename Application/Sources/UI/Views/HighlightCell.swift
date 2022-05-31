//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct HighlightCell: View {
    let highlight: Highlight
    let section: Content.Section
    let filter: SectionFiltering?
    
    @Environment(\.isSelected) private var isSelected
    
    var body: some View {
#if os(tvOS)
        ExpandingCardButton(action: action) {
            MainView(highlight: highlight)
        }
#else
        MainView(highlight: highlight)
            .selectionAppearance(when: isSelected)
            .cornerRadius(LayoutStandardViewCornerRadius)
#endif
    }
    
#if os(tvOS)
    private func action() {
        navigateToSection(section, filter: filter)
    }
#endif
    
    /// Behavior: h-exp, v-exp
    private struct MainView: View {
        let highlight: Highlight
        
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
        
        private var isCompact: Bool {
#if os(iOS)
            return horizontalSizeClass == .compact
#else
            return false
#endif
        }
        
        private var imageUrl: URL? {
            return SRGDataProvider.current!.url(for: highlight.image, size: .large)
        }
        
        var body: some View {
            GeometryReader { geometry in
                if isCompact {
                    ZStack(alignment: .bottom) {
                        ImageView(source: imageUrl, contentMode: .aspectFillTop)
                        LinearGradient(gradient: Gradient(colors: [.srgGray16.opacity(0.9), .clear]), startPoint: .bottom, endPoint: .center)
                        Text(highlight.title)
                            .srgFont(.H2)
                            .lineLimit(2)
                            .foregroundColor(.white)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                else {
                    ZStack(alignment: .leading) {
                        ImageView(source: imageUrl, contentMode: .aspectFillTop)
                        LinearGradient(gradient: Gradient(colors: [.srgGray16.opacity(0.9), .clear]), startPoint: .leading, endPoint: .trailing)
                        DescriptionView(highlight: highlight)
                            .padding(.horizontal, 60)
                            .padding(.vertical, 40)
                            .frame(width: geometry.size.width * 2 / 3, height: geometry.size.height)
                    }
                }
            }
        }
    }
    
    /// Behavior: h-exp, v-hug
    private struct DescriptionView: View {
        let highlight: Highlight
                
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text(highlight.title)
                    .srgFont(.H2)
                    .lineLimit(1)
                if let summary = highlight.summary {
                    Text(summary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .srgFont(.body)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: Size

enum HighlightCellSize {
    static func fullWidth(for highlight: Highlight?, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if let title = highlight?.title, !title.isEmpty {
#if os(tvOS)
            let height: CGFloat = 700
#else
            let height: CGFloat = (horizontalSizeClass == .compact) ? 300 : 400
#endif
            return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(height))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(LayoutHeaderHeightZero))
        }
    }
}

// MARK: Preview

private extension View {
    func previewLayout(for highlight: Highlight, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> some View {
        let size = HighlightCellSize.fullWidth(for: highlight, layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass).previewSize
        return previewLayout(.fixed(width: size.width, height: size.height))
            .horizontalSizeClass(horizontalSizeClass)
    }
}

struct HighlightCell_Previews: PreviewProvider {
    static let highlight = Mock.highlight()
    
    static var previews: some View {
        HighlightCell(highlight: highlight, section: .configured(.tvAllShows), filter: nil)
            .previewLayout(for: highlight, layoutWidth: 1000, horizontalSizeClass: .regular)
#if os(iOS)
        HighlightCell(highlight: highlight, section: .configured(.tvAllShows), filter: nil)
            .previewLayout(for: highlight, layoutWidth: 400, horizontalSizeClass: .compact)
#endif
    }
}
