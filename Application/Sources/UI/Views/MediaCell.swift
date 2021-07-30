//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

// MARK: View

struct MediaCell: View {
    enum Layout {
        case vertical
        case horizontal
        case adaptive
    }
    
    let media: SRGMedia?
    let style: MediaDescription.Style
    let layout: Layout
    let action: (() -> Void)?
    
    fileprivate var onFocusAction: ((Bool) -> Void)?
    
    @State private var isFocused = false
    @Environment(\.isEditing) private var isEditing
    @Environment(\.isSelected) private var isSelected
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #endif
    
    private var direction: StackDirection {
        #if os(iOS)
        if layout == .horizontal || (layout == .adaptive && horizontalSizeClass == .compact) {
            return .horizontal
        }
        #endif
        return .vertical
    }
    
    private var horizontalPadding: CGFloat {
        return direction == .vertical ? 0 : constant(iOS: 10, tvOS: 20)
    }
    
    private var verticalPadding: CGFloat {
        return direction == .vertical ? constant(iOS: 5, tvOS: 15) : 0
    }
    
    init(media: SRGMedia?, style: MediaDescription.Style, layout: Layout = .adaptive, action: (() -> Void)? = nil) {
        self.media = media
        self.style = style
        self.layout = layout
        self.action = action
    }
    
    var body: some View {
        Group {
            #if os(tvOS)
            LabeledCardButton(aspectRatio: MediaCellSize.aspectRatio, action: action ?? defaultAction) {
                MediaVisualView(media: media, scale: .small)
                    .onParentFocusChange(perform: onFocusChange)
                    .unredactable()
                    .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
            } label: {
                DescriptionView(media: media, style: style)
                    .padding(.top, verticalPadding)
            }
            #else
            Stack(direction: direction, spacing: 0) {
                MediaVisualView(media: media, scale: .small)
                    .aspectRatio(MediaCellSize.aspectRatio, contentMode: .fit)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(LayoutStandardViewCornerRadius)
                    .redactable()
                    .layoutPriority(1)
                DescriptionView(media: media, style: style)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, verticalPadding)
            }
            .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: accessibilityTraits)
            #endif
        }
        .redactedIfNil(media)
    }
    
    #if os(tvOS)
    private func defaultAction() {
        if let media = media {
            navigateToMedia(media)
        }
    }
    
    private func onFocusChange(focused: Bool) {
        isFocused = focused
        
        if let onFocusAction = onFocusAction {
            onFocusAction(focused)
        }
    }
    #endif
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        let media: SRGMedia?
        let style: MediaDescription.Style
        
        private var subtitle: String? {
            guard let media = media else { return .placeholder(length: 15) }
            return MediaDescription.subtitle(for: media, style: style)
        }
        
        private var title: String {
            guard let media = media else { return .placeholder(length: 8) }
            return MediaDescription.title(for: media, style: style)
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .srgFont(.subtitle1)
                        .lineLimit(2)
                        .foregroundColor(Color.srgGray96)
                }
                Text(title)
                    .srgFont(.H4)
                    .lineLimit(2)
                    .foregroundColor(Color.srgGrayC7)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        guard let media = media else { return nil }
        return MediaDescription.accessibilityLabel(for: media)
    }
    
    var accessibilityHint: String? {
        return !isEditing ? PlaySRGAccessibilityLocalizedString("Plays the content.", comment: "Media cell hint") : PlaySRGAccessibilityLocalizedString("Edits selection.", comment: "Media cell hint in edit mode")
    }
    
    var accessibilityTraits: AccessibilityTraits {
        return isSelected ? [.isSelected] : []
    }
}

// MARK: Size

class MediaCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    private static let defaultItemWidth: CGFloat = constant(iOS: 210, tvOS: 375)
    private static let heightOffset: CGFloat = constant(iOS: 65, tvOS: 140)
    
    @objc static func swimlane() -> NSCollectionLayoutSize {
        return swimlane(itemWidth: defaultItemWidth)
    }
    
    @objc static func swimlane(itemWidth: CGFloat) -> NSCollectionLayoutSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio, heightOffset)
    }
    
    @objc static func grid(layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> NSCollectionLayoutSize {
        return grid(approximateItemWidth: defaultItemWidth, layoutWidth: layoutWidth, spacing: spacing, minimumNumberOfColumns: minimumNumberOfColumns)
    }
    
    @objc static func grid(approximateItemWidth: CGFloat, layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> NSCollectionLayoutSize {
        return LayoutGridCellSize(approximateItemWidth, aspectRatio, heightOffset, layoutWidth, spacing, minimumNumberOfColumns)
    }
    
    @objc static func fullWidth() -> NSCollectionLayoutSize {
        return fullWidth(itemHeight: constant(iOS: 84, tvOS: 120))
    }
    
    @objc static func fullWidth(itemHeight: CGFloat) -> NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight))
    }
}

// MARK: Preview

struct MediaCell_Previews: PreviewProvider {
    static private let verticalLayoutSize = MediaCellSize.swimlane().previewSize
    static private let horizontalLayoutSize = MediaCellSize.fullWidth().previewSize
    static private let style = MediaDescription.Style.show
    
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
        #endif
    }
}
