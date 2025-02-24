//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct MediaCell: View, PrimaryColorSettable, SecondaryColorSettable {
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

    var primaryColor: Color = .srgGrayD2
    var secondaryColor: Color = .srgGray96

    fileprivate var onFocusAction: ((Bool) -> Void)?

    @State private var isFocused = false

    @Environment(\.isEditing) private var isEditing
    @Environment(\.isSelected) private var isSelected
    @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass

    private var direction: StackDirection {
        if layout == .horizontal || (layout == .adaptive && horizontalSizeClass == .compact) {
            .horizontal
        } else {
            .vertical
        }
    }

    private var horizontalPadding: CGFloat {
        direction == .vertical ? 0 : constant(iOS: 10, tvOS: 20)
    }

    private var verticalPadding: CGFloat {
        direction == .vertical ? constant(iOS: 5, tvOS: 15) : 0
    }

    private var hasSelectionAppearance: Bool {
        isSelected && media != nil
    }

    private var aspectRatio: CGFloat {
        if ApplicationConfiguration.shared.arePodcastImagesEnabled, media?.mediaType == .audio {
            if layout == .adaptive, horizontalSizeClass == .regular {
                MediaCellSize.defaultAspectRatio
            } else {
                MediaSquareCellSize.defaultAspectRatio
            }
        } else {
            MediaCellSize.defaultAspectRatio
        }
    }

    private var contentMode: ContentMode {
        if ApplicationConfiguration.shared.arePodcastImagesEnabled, media?.mediaType == .audio, aspectRatio == MediaCellSize.defaultAspectRatio, horizontalSizeClass != .regular {
            .fill
        } else {
            .fit
        }
    }

    private var visualViewContentMode: ImageView.ContentMode {
        if ApplicationConfiguration.shared.arePodcastImagesEnabled, media?.mediaType == .audio, aspectRatio == MediaSquareCellSize.defaultAspectRatio {
            .aspectFill
        } else {
            .aspectFit
        }
    }

    private var isSmallAudioSquaredCell: Bool {
        ApplicationConfiguration.shared.arePodcastImagesEnabled && media?.mediaType == .audio && direction == .horizontal
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
                LabeledCardButton(aspectRatio: MediaCellSize.defaultAspectRatio, action: action ?? defaultAction) {
                    MediaVisualView(media: media, size: .small)
                        .onParentFocusChange(perform: onFocusChange)
                        .unredactable()
                        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: accessibilityTraits)
                } label: {
                    DescriptionView(media: media, style: style)
                        .primaryColor(primaryColor)
                        .secondaryColor(secondaryColor)
                        .padding(.top, verticalPadding)
                }
            #else
                Stack(direction: .vertical, spacing: 0) {
                    Stack(direction: direction, spacing: 0) {
                        MediaVisualView(media: media, size: .small, contentMode: visualViewContentMode, embeddedDirection: direction)
                            .aspectRatio(aspectRatio, contentMode: contentMode)
                            .selectionAppearance(when: hasSelectionAppearance, while: isEditing)
                            .cornerRadius(LayoutStandardViewCornerRadius)
                            .redactable()
                            .layoutPriority(isSmallAudioSquaredCell ? 0 : 1)
                        DescriptionView(media: media, style: style, embeddedDirection: direction)
                            .primaryColor(primaryColor)
                            .secondaryColor(secondaryColor)
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
    private struct DescriptionView: View, PrimaryColorSettable, SecondaryColorSettable {
        let media: SRGMedia?
        let style: MediaCell.Style
        let embeddedDirection: StackDirection

        var primaryColor: Color = .srgGrayD2
        var secondaryColor: Color = .srgGray96

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
            return MediaDescription.title(for: media)
        }

        private var summary: String? {
            guard horizontalSizeClass == .regular, style == .dateAndSummary else { return nil }

            guard let media else { return .placeholder(length: 15) }
            return MediaDescription.summary(for: media)
        }

        private var mediaDescriptionStyle: MediaDescription.Style {
            switch style {
            case .show:
                .show
            case .date, .dateAndSummary:
                .date
            case .time:
                .time
            }
        }

        private var titleLineLimit: Int {
            if horizontalSizeClass == .regular, style == .dateAndSummary {
                1
            } else {
                embeddedDirection == .horizontal ? 3 : 2
            }
        }

        private var bottomPadding: CGFloat {
            // Allow 3 lines for title, with a badge and no subtitles
            embeddedDirection == .horizontal ? -2 : 0
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
                        .foregroundColor(secondaryColor)
                }
                if let title {
                    Text(title)
                        .srgFont(.H4)
                        .lineLimit(titleLineLimit)
                        .foregroundColor(primaryColor)
                        .layoutPriority(1)
                }
                if let summary {
                    Text(summary)
                        .srgFont(.body)
                        .lineLimit(2)
                        .foregroundColor(primaryColor)
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
        return MediaDescription.cellAccessibilityLabel(for: media)
    }

    var accessibilityHint: String? {
        !isEditing ? PlaySRGAccessibilityLocalizedString("Plays the content.", comment: "Media cell hint") : PlaySRGAccessibilityLocalizedString("Toggles selection.", comment: "Media cell hint in edit mode")
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
    fileprivate static let defaultAspectRatio: CGFloat = 16 / 9

    private static let defaultItemWidth: CGFloat = constant(iOS: 210, tvOS: 375)
    private static let heightOffset: CGFloat = constant(iOS: 65, tvOS: 140)

    static func swimlane() -> NSCollectionLayoutSize {
        LayoutSwimlaneCellSize(defaultItemWidth, defaultAspectRatio, heightOffset)
    }

    static func grid(layoutWidth: CGFloat, spacing: CGFloat) -> NSCollectionLayoutSize {
        LayoutGridCellSize(defaultItemWidth, defaultAspectRatio, heightOffset, layoutWidth, spacing, 1)
    }

    static func fullWidth(horizontalSizeClass: UIUserInterfaceSizeClass = .compact) -> NSCollectionLayoutSize {
        let height = height(horizontalSizeClass: horizontalSizeClass)
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(CGFloat(height)))
    }

    static func height(horizontalSizeClass: UIUserInterfaceSizeClass) -> CGFloat {
        horizontalSizeClass == .compact ? constant(iOS: 84, tvOS: 120) : constant(iOS: 104, tvOS: 120)
    }
}

final class MediaSquareCellSize: NSObject {
    fileprivate static let defaultAspectRatio: CGFloat = 1

    private static let defaultItemWidth: CGFloat = constant(iOS: 148, tvOS: 258)
    private static let heightOffset: CGFloat = constant(iOS: 44, tvOS: 78)

    static func swimlane() -> NSCollectionLayoutSize {
        LayoutSwimlaneCellSize(defaultItemWidth, defaultAspectRatio, heightOffset)
    }

    static func grid(layoutWidth: CGFloat, spacing: CGFloat) -> NSCollectionLayoutSize {
        LayoutGridCellSize(defaultItemWidth, defaultAspectRatio, heightOffset, layoutWidth, spacing, 1)
    }

    static func fullWidth() -> NSCollectionLayoutSize {
        let height = height()
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(CGFloat(height)))
    }

    static func height() -> CGFloat {
        constant(iOS: 148, tvOS: 258)
    }
}

final class SmallMediaSquareCellSize: NSObject {
    fileprivate static let defaultAspectRatio: CGFloat = 1

    private static let defaultItemWidth: CGFloat = constant(iOS: 84, tvOS: 120)
    private static let heightOffset: CGFloat = constant(iOS: 65, tvOS: 140)

    static func swimlane() -> NSCollectionLayoutSize {
        LayoutSwimlaneCellSize(defaultItemWidth, defaultAspectRatio, heightOffset)
    }

    static func grid(layoutWidth: CGFloat, spacing: CGFloat) -> NSCollectionLayoutSize {
        LayoutGridCellSize(defaultItemWidth, defaultAspectRatio, 0, layoutWidth, spacing, 1)
    }

    static func fullWidth() -> NSCollectionLayoutSize {
        let height = height()
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(CGFloat(height)))
    }

    static func height() -> CGFloat {
        constant(iOS: 84, tvOS: 120)
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
            MediaCell(media: Mock.media(), style: style, layout: .vertical)
            MediaCell(media: Mock.media(.noShow), style: style, layout: .vertical)
            MediaCell(media: Mock.media(.rich), style: style, layout: .vertical)
            MediaCell(media: Mock.media(.overflow), style: style, layout: .vertical)
            MediaCell(media: Mock.media(.nineSixteen), style: style, layout: .vertical)
        }
        .previewLayout(.fixed(width: verticalLayoutSize.width, height: verticalLayoutSize.height))

        #if os(iOS)
            Group {
                MediaCell(media: Mock.media(), style: style, layout: .horizontal)
                MediaCell(media: Mock.media(.noShow), style: style, layout: .horizontal)
                MediaCell(media: Mock.media(.rich), style: style, layout: .horizontal)
                MediaCell(media: Mock.media(.overflow), style: style, layout: .horizontal)
                MediaCell(media: Mock.media(.nineSixteen), style: style, layout: .horizontal)
            }
            .previewLayout(.fixed(width: horizontalLayoutSize.width, height: horizontalLayoutSize.height))

            Group {
                MediaCell(media: Mock.media(), style: largeListStyle, layout: .horizontal)
                MediaCell(media: Mock.media(.noShow), style: largeListStyle, layout: .horizontal)
                MediaCell(media: Mock.media(.rich), style: largeListStyle, layout: .horizontal)
                MediaCell(media: Mock.media(.overflow), style: largeListStyle, layout: .horizontal)
                MediaCell(media: Mock.media(.nineSixteen), style: largeListStyle, layout: .horizontal)
            }
            .previewLayout(.fixed(width: horizontalLargeListLayoutSize.width, height: horizontalLargeListLayoutSize.height))
        #endif
    }
}
