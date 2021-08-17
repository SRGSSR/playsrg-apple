//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct ShowCell: View {
    enum Style {
        case standard
        case favorite
    }
    
    @Binding private(set) var show: SRGShow?
    
    let style: Style
    let imageType: SRGImageType

    @StateObject private var model = ShowCellViewModel()
    
    @Environment(\.isEditing) private var isEditing
    @Environment(\.isSelected) private var isSelected
    
    init(show: SRGShow?, style: Style, imageType: SRGImageType) {
        _show = .constant(show)
        self.style = style
        self.imageType = imageType
    }
    
    var body: some View {
        Group {
            #if os(tvOS)
            LabeledCardButton(aspectRatio: ShowCellSize.aspectRatio(for: imageType), action: action) {
                ImageView(url: model.imageUrl)
                    .unredactable()
                    .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
            } label: {
                DescriptionView(model: model, style: style)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, ShowCellSize.verticalPadding)
            }
            #else
            VStack(spacing: 0) {
                ImageView(url: model.imageUrl)
                    .aspectRatio(ShowCellSize.aspectRatio(for: imageType), contentMode: .fit)
                    .background(Color.white.opacity(0.1))
                DescriptionView(model: model, style: style)
                    .padding(.horizontal, ShowCellSize.horizontalPadding)
                    .padding(.vertical, ShowCellSize.verticalPadding)
            }
            .background(Color.srgGray23)
            .redactable()
            .selectionAppearance(when: isSelected, while: isEditing)
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: accessibilityTraits)
            .frame(maxHeight: .infinity, alignment: .top)
            #endif
        }
        .redactedIfNil(show)
        .onAppear {
            model.show = show
        }
        .onChange(of: show) { newValue in
            model.show = newValue
        }
    }
    
    #if os(tvOS)
    private func action() {
        if let show = show {
            navigateToShow(show)
        }
    }
    #endif
    
    /// Behavior: h-exp, v-hug
    private struct DescriptionView: View {
        @ObservedObject var model: ShowCellViewModel
        let style: Style
        
        var body: some View {
            HStack {
                Text(model.title ?? "")
                    .srgFont(.H4)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                if style == .favorite, model.isSubscribed {
                    Image("subscription_full")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 12)
                }
            }
            .foregroundColor(.srgGrayC7)
        }
    }
}

// MARK: Accessibility

private extension ShowCell {
    var accessibilityLabel: String? {
        return model.title
    }
    
    var accessibilityHint: String? {
        return !isEditing ? PlaySRGAccessibilityLocalizedString("Opens show details.", comment: "Show cell hint") : PlaySRGAccessibilityLocalizedString("Toggles selection.", comment: "Show cell hint in edit mode")
    }
    
    var accessibilityTraits: AccessibilityTraits {
        return isSelected ? .isSelected : []
    }
}

// MARK: Size

final class ShowCellSize: NSObject {
    fileprivate static let horizontalPadding: CGFloat = constant(iOS: 10, tvOS: 0)
    fileprivate static let verticalPadding: CGFloat = constant(iOS: 5, tvOS: 7)
    
    private static let heightOffset: CGFloat = constant(iOS: 32, tvOS: 45)
    
    fileprivate static func aspectRatio(for imageType: SRGImageType) -> CGFloat {
        return imageType == .showPoster ? 2 / 3 : 16 / 9
    }
    
    fileprivate static func itemWidth(for imageType: SRGImageType) -> CGFloat {
        return imageType == .showPoster ? constant(iOS: 158, tvOS: 276) : constant(iOS: 210, tvOS: 375)
    }
    
    @objc static func swimlane(for imageType: SRGImageType) -> NSCollectionLayoutSize {
        return swimlane(for: imageType, itemWidth: itemWidth(for: imageType))
    }
    
    @objc static func swimlane(for imageType: SRGImageType, itemWidth: CGFloat) -> NSCollectionLayoutSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio(for: imageType), heightOffset)
    }
    
    @objc static func grid(for imageType: SRGImageType, layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> NSCollectionLayoutSize {
        return grid(for: imageType, approximateItemWidth: itemWidth(for: imageType), layoutWidth: layoutWidth, spacing: spacing, minimumNumberOfColumns: minimumNumberOfColumns)
    }
    
    @objc static func grid(for imageType: SRGImageType, approximateItemWidth: CGFloat, layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> NSCollectionLayoutSize {
        return LayoutGridCellSize(approximateItemWidth, aspectRatio(for: imageType), heightOffset, layoutWidth, spacing, minimumNumberOfColumns)
    }
}

// MARK: Preview

struct ShowCell_Previews: PreviewProvider {
    private static let size = ShowCellSize.swimlane(for: .default).previewSize
    
    static var previews: some View {
        ShowCell(show: Mock.show(.standard), style: .standard, imageType: .default)
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
