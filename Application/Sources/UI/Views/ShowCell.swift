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
            LabeledCardButton(action: action) {
                ImageView(url: show?.imageUrl(for: .small))
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .accessibilityElement()
                    .accessibilityOptionalLabel(show?.title)
                    .accessibility(addTraits: .isButton)
            } label: {
                DescriptionView(show: show)
            }
            #else
            Stack(direction: direction) {
                ImageView(url: show?.imageUrl(for: .small))
                    .aspectRatio(16 / 9, contentMode: .fit)
                DescriptionView(show: show)
            }
            .background(Color(.play_cardGrayBackground))
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityOptionalLabel(show?.title)
            #endif
        }
        .redactedIfNil(show)
    }
    
    #if os(tvOS)
    func action() {
        if let show = show {
            navigateToShow(show)
        }
    }
    #endif
    
    private struct DescriptionView: View {
        let show: SRGShow?
        
        private var title: String {
            return show?.title ?? String(repeating: " ", count: .random(in: 10..<20))
        }
        
        var body: some View {
            Text(title)
                .srgFont(.subtitle)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

struct ShowCell_Previews: PreviewProvider {
    static private let size = LayoutCollectionItemSize(LayoutStandardCellWidth, .showSwimlaneOrGrid, .regular)
    
    static var previews: some View {
        ShowCell(show: MockData.show())
            .previewDisplayName("Cell")
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
