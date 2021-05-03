//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

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
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var direction: StackDirection {
        if layout == .horizontal || (layout == .adaptive && horizontalSizeClass == .compact) {
            return .horizontal
        }
        else {
            return .vertical
        }
    }
    #endif
    
    private var horizontalPadding: CGFloat {
        return direction == .vertical ? 0 : MediaCellSize.horizontalPadding
    }
    
    private var verticalPadding: CGFloat {
        return direction == .vertical ? MediaCellSize.verticalPadding : 0
    }
    
    init(media: SRGMedia?, style: MediaDescription.Style = .date, layout: Layout = .adaptive, action: (() -> Void)? = nil) {
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
                    .accessibilityElement()
                    .accessibilityOptionalLabel(MediaDescription.accessibilityLabel(for: media))
                    .accessibility(addTraits: .isButton)
            } label: {
                DescriptionView(media: media, style: style)
                    .padding(.top, MediaCellSize.verticalPadding)
            }
            #else
            Stack(direction: direction, spacing: 0) {
                MediaVisualView(media: media, scale: .small)
                    .aspectRatio(MediaCellSize.aspectRatio, contentMode: .fit)
                    .cornerRadius(LayoutStandardViewCornerRadius)
                    .redactable()
                    .layoutPriority(1)
                DescriptionView(media: media, style: style)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, verticalPadding)
            }
            .accessibilityElement()
            .accessibilityOptionalLabel(MediaDescription.accessibilityLabel(for: media))
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
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(MediaDescription.title(for: media, style: style) ?? String.placeholder(length: 8))
                    .srgFont(.subtitle1)
                    .lineLimit(2)
                    .foregroundColor(Color(.play_gray))
                Text(MediaDescription.subtitle(for: media, style: style) ?? String.placeholder(length: 15))
                    .srgFont(.H4)
                    .lineLimit(2)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

extension MediaCell {
    func onFocus(perform action: @escaping (Bool) -> Void) -> MediaCell {
        var mediaCell = self
        mediaCell.onFocusAction = action
        return mediaCell
    }
}

class MediaCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    fileprivate static let verticalPadding: CGFloat = constant(iOS: 5, tvOS: 15)
    fileprivate static let horizontalPadding: CGFloat = constant(iOS: 10, tvOS: 20)
    
    private static let defaultItemWidth: CGFloat = constant(iOS: 210, tvOS: 375)
    private static let defaultTableItemHeight: CGFloat = constant(iOS: 84, tvOS: 120)
    private static let heightOffset: CGFloat = constant(iOS: 65, tvOS: 95)
    
    @objc static func swimlane() -> CGSize {
        return swimlane(itemWidth: defaultItemWidth)
    }
    
    @objc static func swimlane(itemWidth: CGFloat) -> CGSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio, heightOffset)
    }
    
    @objc static func grid(layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> CGSize {
        return grid(approximateItemWidth: defaultItemWidth, layoutWidth: layoutWidth, spacing: spacing, minimumNumberOfColumns: minimumNumberOfColumns)
    }
    
    @objc static func grid(approximateItemWidth: CGFloat, layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> CGSize {
        return LayoutGridCellSize(approximateItemWidth, aspectRatio, heightOffset, layoutWidth, spacing, minimumNumberOfColumns)
    }
    
    @objc static func fullWidth(layoutWidth: CGFloat) -> CGSize {
        return fullWidth(itemHeight: defaultTableItemHeight, layoutWidth: layoutWidth)
    }
    
    @objc static func fullWidth(itemHeight: CGFloat, layoutWidth: CGFloat) -> CGSize {
        return CGSize(width: layoutWidth, height: itemHeight)
    }
}

struct MediaCell_Previews: PreviewProvider {
    static private let verticalLayoutSize = MediaCellSize.swimlane()
    static private let horizontalLayoutSize = MediaCellSize.fullWidth(layoutWidth: 600)
    static private let style = MediaDescription.Style.show
    
    static var previews: some View {
        Group {
            MediaCell(media: Mock.media(), style: Self.style, layout: .vertical)
            MediaCell(media: Mock.media(.rich), style: Self.style, layout: .vertical)
            MediaCell(media: Mock.media(.overflow), style: Self.style, layout: .vertical)
            MediaCell(media: Mock.media(.nineSixteen), style: Self.style, layout: .vertical)
        }
        .previewLayout(.fixed(width: verticalLayoutSize.width, height: verticalLayoutSize.height))
        
        #if os(iOS)
        Group {
            MediaCell(media: Mock.media(), style: Self.style, layout: .horizontal)
            MediaCell(media: Mock.media(.rich), style: Self.style, layout: .horizontal)
            MediaCell(media: Mock.media(.overflow), style: Self.style, layout: .horizontal)
            MediaCell(media: Mock.media(.nineSixteen), style: Self.style, layout: .horizontal)
        }
        .previewLayout(.fixed(width: horizontalLayoutSize.width, height: horizontalLayoutSize.height))
        #endif
    }
}
