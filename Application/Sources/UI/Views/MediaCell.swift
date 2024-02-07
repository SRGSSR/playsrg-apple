//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct MediaCell: View {
    enum Layout {
        case vertical
        case horizontal
        case adaptive
    }
    
    enum Style {
        /// Show information emphasis
        case show
        /// Date information emphasis
        case date
        /// Date information emphasis with summary
        case dateAndSummary
        /// Time information emphasis
        case time
    }
    
    let media: SRGMedia?
    let style: Style
    let layout: Layout
    let action: (() -> Void)?
    
    fileprivate var onFocusAction: ((Bool) -> Void)?
    
    @State private var isFocused = false
    
    @Environment(\.isEditing) private var isEditing
    @Environment(\.isSelected) private var isSelected
    @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass
    
    private var direction: StackDirection {
        if layout == .horizontal || (layout == .adaptive && horizontalSizeClass == .compact) {
            return .horizontal
        }
        else {
            return .vertical
        }
    }
    
    private var horizontalPadding: CGFloat {
        return direction == .vertical ? 0 : constant(iOS: 10, tvOS: 20)
    }
    
    private var verticalPadding: CGFloat {
        return direction == .vertical ? constant(iOS: 5, tvOS: 15) : 0
    }
    
    private var hasSelectionAppearance: Bool {
        return isSelected && media != nil
    }
    
    init(media: SRGMedia?, style: Style, layout: Layout = .adaptive, action: (() -> Void)? = nil) {
        self.media = media
        self.style = style
        self.layout = layout
        self.action = action
    }
    
    var body: some View {
        Group {
#if os(tvOS)
            LabeledCardButton(aspectRatio: MediaCellSize.aspectRatio, action: action ?? defaultAction) {
                MediaVisualView(media: media, size: .small)
                    .onParentFocusChange(perform: onFocusChange)
                    .unredactable()
                    .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: accessibilityTraits)
            } label: {
                DescriptionView(media: media, style: style)
                    .padding(.top, verticalPadding)
            }
#else
            Stack(direction: .vertical, spacing: 0) {
                Stack(direction: direction, spacing: 0) {
                    MediaVisualView(media: media, size: .small, embeddedDirection: direction)
                        .aspectRatio(MediaCellSize.aspectRatio, contentMode: .fit)
                        .selectionAppearance(when: hasSelectionAppearance, while: isEditing)
                        .cornerRadius(LayoutStandardViewCornerRadius)
                        .redactable()
                        .layoutPriority(1)
                    DescriptionView(media: media, style: style, embeddedDirection: direction)
                        .selectionAppearance(.transluscent, when: hasSelectionAppearance, while: isEditing)
                        .padding(.leading, horizontalPadding)
                        .padding(.top, verticalPadding)
                    if direction == .horizontal, style == .dateAndSummary, horizontalSizeClass == .regular, let media {
                        MediaMoreButton(media: media)
                    }
                }
            }
            .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: accessibilityTraits)
#endif
        }
        .redactedIfNil(media)
    }
    
#if os(tvOS)
    private func defaultAction() {
        if let media {
            navigateToMedia(media)
        }
    }
    
    private func onFocusChange(focused: Bool) {
        isFocused = focused
        
        if let onFocusAction {
            onFocusAction(focused)
        }
    }
#endif
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        let media: SRGMedia?
        let style: MediaCell.Style
        let embeddedDirection: StackDirection
        
        init(
            media: SRGMedia?,
            style: MediaCell.Style,
            embeddedDirection: StackDirection = .vertical
        ) {
            self.media = media
            self.style = style
            self.embeddedDirection = embeddedDirection
        }
        
        private var availabilityBadgeProperties: MediaDescription.BadgeProperties? {
            guard let media else { return nil }
            return MediaDescription.availabilityBadgeProperties(for: media)
        }
        
        @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass
        
        private var subtitle: String? {
            guard let media else { return .placeholder(length: 15) }
            return MediaDescription.subtitle(for: media, style: mediaDescriptionStyle)
        }
        
        private var title: String? {
            guard let media else { return .placeholder(length: 8) }
            return MediaDescription.title(for: media, style: mediaDescriptionStyle)
        }
        
        private var summary: String? {
            guard horizontalSizeClass == .regular, style == .dateAndSummary else { return nil }
            
            guard let media else { return .placeholder(length: 15) }
            return MediaDescription.summary(for: media)
        }
        
        private var mediaDescriptionStyle: MediaDescription.Style {
            switch style {
            case .show:
                return .show
            case .date, .dateAndSummary:
                return .date
            case .time:
                return .time
            }
        }
        
        private var titleLineLimit: Int {
            if horizontalSizeClass == .regular && style == .dateAndSummary {
                return 1
            }
            else {
                return embeddedDirection == .horizontal ? 3 : 2
            }
        }
        
        private var bottomPadding: CGFloat {
            // Allow 3 lines for titles, with a badge and no subtitles
            return embeddedDirection == .horizontal ? -2 : 0
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                if embeddedDirection == .horizontal, let properties = availabilityBadgeProperties {
                    Badge(text: properties.text, color: Color(properties.color))
                        .padding(.bottom, 4)
                }
                if let subtitle {
                    Text(subtitle)
                        .srgFont(.subtitle1)
                        .lineLimit(2)
                        .foregroundColor(.srgGray96)
                }
                if let title {
                    Text(title)
                        .srgFont(.H4)
                        .lineLimit(titleLineLimit)
                        .foregroundColor(.srgGrayC7)
                        .layoutPriority(1)
                }
                if let summary {
                    Text(summary)
                        .srgFont(.body)
                        .lineLimit(2)
                        .foregroundColor(.srgGrayC7)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.bottom, bottomPadding)
        }
    }
}

// MARK: Modifiers

extension MediaCell {
    func onFocus(perform action: @escaping (Bool) -> Void) -> MediaCell {
        var mediaCell = self
        mediaCell.onFocusAction = action
        return mediaCell
    }
}

// MARK: Accessibility

private extension MediaCell {
    var accessibilityLabel: String? {
        guard let media else { return nil }
        return MediaDescription.accessibilityLabel(for: media)
    }
    
    var accessibilityHint: String? {
        return !isEditing ? PlaySRGAccessibilityLocalizedString("Plays the content.", comment: "Media cell hint") : PlaySRGAccessibilityLocalizedString("Toggles selection.", comment: "Media cell hint in edit mode")
    }
    
    var accessibilityTraits: AccessibilityTraits {
#if os(tvOS)
        return .isButton
#else
        return isSelected ? .isSelected : []
#endif
    }
}

// MARK: Size

final class MediaCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    private static let defaultItemWidth: CGFloat = constant(iOS: 210, tvOS: 375)
    private static let heightOffset: CGFloat = constant(iOS: 65, tvOS: 140)
    
    static func swimlane(itemWidth: CGFloat = defaultItemWidth) -> NSCollectionLayoutSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio, heightOffset)
    }
    
    static func grid(layoutWidth: CGFloat, spacing: CGFloat) -> NSCollectionLayoutSize {
        return LayoutGridCellSize(defaultItemWidth, aspectRatio, heightOffset, layoutWidth, spacing, 1)
    }
    
    static func fullWidth(horizontalSizeClass: UIUserInterfaceSizeClass = .compact) -> NSCollectionLayoutSize {
        let height = horizontalSizeClass == .compact ? constant(iOS: 84, tvOS: 120) : constant(iOS: 104, tvOS: 120)
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(CGFloat(height)))
    }
}

// MARK: Preview

struct MediaCell_Previews: PreviewProvider {
    private static let verticalLayoutSize = MediaCellSize.swimlane().previewSize
    private static let horizontalLayoutSize = MediaCellSize.fullWidth().previewSize
    private static let horizontalLargeListLayoutSize = MediaCellSize.fullWidth(horizontalSizeClass: .regular).previewSize
    private static let style = MediaCell.Style.show
    private static let largeListStyle = MediaCell.Style.dateAndSummary
    
    static var previews: some View {
        Group {
            MediaCell(media: Mock.media(), style: Self.style, layout: .vertical)
            MediaCell(media: Mock.media(.noShow), style: Self.style, layout: .vertical)
            MediaCell(media: Mock.media(.rich), style: Self.style, layout: .vertical)
            MediaCell(media: Mock.media(.overflow), style: Self.style, layout: .vertical)
            MediaCell(media: Mock.media(.nineSixteen), style: Self.style, layout: .vertical)
        }
        .previewLayout(.fixed(width: verticalLayoutSize.width, height: verticalLayoutSize.height))
        
#if os(iOS)
        Group {
            MediaCell(media: Mock.media(), style: Self.style, layout: .horizontal)
            MediaCell(media: Mock.media(.noShow), style: Self.style, layout: .horizontal)
            MediaCell(media: Mock.media(.rich), style: Self.style, layout: .horizontal)
            MediaCell(media: Mock.media(.overflow), style: Self.style, layout: .horizontal)
            MediaCell(media: Mock.media(.nineSixteen), style: Self.style, layout: .horizontal)
        }
        .previewLayout(.fixed(width: horizontalLayoutSize.width, height: horizontalLayoutSize.height))
        
        Group {
            MediaCell(media: Mock.media(), style: Self.largeListStyle, layout: .horizontal)
            MediaCell(media: Mock.media(.noShow), style: Self.largeListStyle, layout: .horizontal)
            MediaCell(media: Mock.media(.rich), style: Self.largeListStyle, layout: .horizontal)
            MediaCell(media: Mock.media(.overflow), style: Self.largeListStyle, layout: .horizontal)
            MediaCell(media: Mock.media(.nineSixteen), style: Self.largeListStyle, layout: .horizontal)
        }
        .previewLayout(.fixed(width: horizontalLargeListLayoutSize.width, height: horizontalLargeListLayoutSize.height))
#endif
    }
}
