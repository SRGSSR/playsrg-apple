//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// TODO: Improve implementation once we know what to do
struct MoreCell: View {
    let section: Content.Section
    let filter: SectionFiltering?
    
    static let iconHeight: CGFloat = constant(iOS: 60, tvOS: 100)
    static let aspectRatio: CGFloat = 16 / 9
    
    var body: some View {
        #if os(tvOS)
        LabeledCardButton(aspectRatio: Self.aspectRatio, action: action) {
            Image("chevron")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: Self.iconHeight)
                .foregroundColor(.srgGray5)
                .opacity(0.8)
                .accessibilityElement()
                .accessibilityOptionalLabel(NSLocalizedString("More", comment: "More button accessibility label"))
                .accessibility(addTraits: .isButton)
        } label: {
            Color.clear
        }
        #else
        Image("chevron")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: Self.iconHeight)
            .foregroundColor(.srgGray5)
            .opacity(0.8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .background(Color.white.opacity(0.1))
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityOptionalLabel(NSLocalizedString("More", comment: "More button accessibility label"))
            .frame(maxHeight: .infinity, alignment: .top)
        #endif
    }
    
    #if os(tvOS)
    private func action() {
        navigateToSection(section, filter: filter)
    }
    #endif
}

struct MoreCell_Previews: PreviewProvider {
    static var previews: some View {
        MoreCell(section: .configured(ConfiguredSection(type: .tvLive, contentPresentationType: .grid)), filter: nil)
            .previewLayout(.fixed(width: 400, height: 400))
    }
}
