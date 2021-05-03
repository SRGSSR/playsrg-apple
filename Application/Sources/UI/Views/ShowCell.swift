//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ShowCell: View {
    let show: SRGShow?
    let direction: StackDirection
    
    init(show: SRGShow?, direction: StackDirection = .vertical) {
        self.show = show
        self.direction = direction
    }
    
    var body: some View {
        Group {
            #if os(tvOS)
            LabeledCardButton(aspectRatio: ShowCellSize.aspectRatio, action: action) {
                ImageView(url: show?.imageUrl(for: .small))
                    .unredactable()
                    .accessibilityElement()
                    .accessibilityOptionalLabel(show?.title)
                    .accessibility(addTraits: .isButton)
            } label: {
                DescriptionView(show: show)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, ShowCellSize.verticalPadding)
            }
            #else
            Stack(direction: direction, spacing: 0) {
                ImageView(url: show?.imageUrl(for: .small))
                    .aspectRatio(ShowCellSize.aspectRatio, contentMode: .fit)
                DescriptionView(show: show)
                    .padding(.horizontal, ShowCellSize.horizontalPadding)
                    .padding(.vertical, ShowCellSize.verticalPadding)
            }
            .background(Color(.play_cardGrayBackground))
            .redactable()
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityOptionalLabel(show?.title)
            .frame(maxHeight: .infinity, alignment: .top)
            #endif
        }
        .redactedIfNil(show)
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
        let show: SRGShow?
        
        var body: some View {
            Text(show?.title ?? "")
                .srgFont(.H4)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

class ShowCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    fileprivate static let horizontalPadding: CGFloat = constant(iOS: 10, tvOS: 0)
    fileprivate static let verticalPadding: CGFloat = constant(iOS: 10, tvOS: 7)
    
    private static let defaultItemWidth: CGFloat = constant(iOS: 210, tvOS: 375)
    private static let defaultTableItemHeight: CGFloat = constant(iOS: 84, tvOS: 120)
    private static let heightOffset: CGFloat = constant(iOS: 32, tvOS: 45)
    
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

struct ShowCell_Previews: PreviewProvider {
    static private let size = ShowCellSize.swimlane()
    
    static var previews: some View {
        ShowCell(show: Mock.show(.standard))
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
