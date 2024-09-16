//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct HighlightCell: View {
    let highlight: Highlight?
    let section: Content.Section
    let item: Content.Item?
    let filter: SectionFiltering?

    @Environment(\.isSelected) private var isSelected

    var body: some View {
        #if os(tvOS)
            ExpandingCardButton(action: action) {
                MainView(highlight: highlight)
                    .redactable()
                    .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
            }
        #else
            MainView(highlight: highlight)
                .selectionAppearance(when: isSelected && highlight != nil)
                .cornerRadius(LayoutStandardViewCornerRadius)
                .redactable()
                .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
        #endif
    }

    #if os(tvOS)
        private func action() {
            if case let .show(show) = item {
                navigateToShow(show)
            } else if case let .media(media) = item {
                navigateToMedia(media)
            } else {
                navigateToSection(section, filter: filter)
            }
        }
    #endif

    /// Behavior: h-exp, v-exp
    private struct MainView: View {
        let highlight: Highlight?

        @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass

        private var direction: StackDirection {
            (horizontalSizeClass == .compact) ? .vertical : .horizontal
        }

        private var isCompact: Bool {
            horizontalSizeClass == .compact
        }

        private var imageUrl: URL? {
            guard let highlight else { return nil }
            return url(for: highlight.image, size: .large)
        }

        private var contentMode: ImageView.ContentMode {
            if let focalPoint = highlight?.imageFocalPoint {
                .aspectFillFocused(relativeWidth: focalPoint.relativeWidth, relativeHeight: focalPoint.relativeHeight)
            } else {
                .aspectFillRight
            }
        }

        var body: some View {
            GeometryReader { geometry in
                if isCompact {
                    ZStack(alignment: .bottom) {
                        ImageView(source: imageUrl, contentMode: contentMode)
                        if let highlight {
                            DiagonalGradientView(midwayStop: 0.5)
                            VerticalGradientView(midwayStop: 0.3)
                            Text(highlight.title)
                                .srgFont(.H2)
                                .lineLimit(2)
                                .foregroundColor(.white)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else {
                    ZStack(alignment: .leading) {
                        ImageView(source: imageUrl, contentMode: contentMode)
                        if let highlight {
                            DiagonalGradientView(midwayStop: 0.6)
                            VerticalGradientView(midwayStop: 0.5)
                            DescriptionView(highlight: highlight)
                                .padding(32)
                                .frame(width: geometry.size.width * 2 / 3, height: geometry.size.height, alignment: .bottomLeading)
                        }
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private struct VerticalGradientView: View {
        let midwayStop: CGFloat
        var body: some View {
            let stops = [Gradient.Stop(color: .srgGray16.opacity(0.6), location: 0.0), Gradient.Stop(color: .srgGray16.opacity(0.0), location: midwayStop)]
            return LinearGradient(stops: stops, startPoint: .bottom, endPoint: .top)
        }
    }

    private struct DiagonalGradientView: View {
        let midwayStop: CGFloat
        var body: some View {
            let stops = [Gradient.Stop(color: .srgGray16.opacity(0.6), location: 0.0), Gradient.Stop(color: .srgGray16.opacity(0.0), location: midwayStop)]
            return LinearGradient(stops: stops, startPoint: UnitPoint(x: 0, y: 1), endPoint: UnitPoint(x: 0.2, y: 0.0))
        }
    }
}

// MARK: Accessibility

private extension HighlightCell {
    var accessibilityLabel: String? {
        highlight?.title
    }

    var accessibilityHint: String? {
        PlaySRGAccessibilityLocalizedString("Opens details.", comment: "Highlight cell hint")
    }
}

// MARK: Size

enum HighlightCellSize {
    private static func aspectRatio(horizontalSizeClass: UIUserInterfaceSizeClass) -> CGFloat {
        horizontalSizeClass == .compact ? 16 / 9 : 4
    }

    static func fullWidth(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        LayoutSwimlaneCellSize(layoutWidth, aspectRatio(horizontalSizeClass: horizontalSizeClass), 0)
    }
}

// MARK: Preview

private extension View {
    func previewLayout(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> some View {
        let size = HighlightCellSize.fullWidth(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass).previewSize
        return previewLayout(.fixed(width: size.width, height: size.height))
            .horizontalSizeClass(horizontalSizeClass)
    }
}

struct HighlightCell_Previews: PreviewProvider {
    static let highlight = Mock.highlight()

    static var previews: some View {
        HighlightCell(highlight: highlight, section: .configured(.tvAllShows), item: nil, filter: nil)
            .previewLayout(layoutWidth: 1000, horizontalSizeClass: .regular)
        #if os(iOS)
            HighlightCell(highlight: highlight, section: .configured(.tvAllShows), item: nil, filter: nil)
                .previewLayout(layoutWidth: 400, horizontalSizeClass: .compact)
        #endif
    }
}
