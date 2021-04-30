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
            LabeledCardButton(aspectRatio: 16 / 9, action: action) {
                ImageView(url: show?.imageUrl(for: .small))
                    .accessibilityElement()
                    .accessibilityOptionalLabel(show?.title)
                    .accessibility(addTraits: .isButton)
            } label: {
                DescriptionView(show: show)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            #else
            Stack(direction: direction, spacing: 0) {
                ImageView(url: show?.imageUrl(for: .small))
                    .aspectRatio(16 / 9, contentMode: .fit)
                DescriptionView(show: show)
            }
            .background(Color(.play_cardGrayBackground))
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
                .srgFont(.subtitle)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

struct ShowCell_Previews: PreviewProvider {
    static private let size = LayoutHorizontalCellSize(210, 16 / 9, 29)
    
    static var previews: some View {
        ShowCell(show: Mock.show(.standard))
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
