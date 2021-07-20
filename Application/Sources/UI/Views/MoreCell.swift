//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

// TODO: Improve implementation once we know what to do
struct MoreCell: View {
    let section: Content.Section
    let filter: SectionFiltering?
    
    static let iconHeight: CGFloat = constant(iOS: 60, tvOS: 100)
    static let aspectRatio: CGFloat = 16 / 9
    
    var body: some View {
        #if os(tvOS)
        LabeledCardButton(aspectRatio: Self.aspectRatio, action: action) {
            Image("chevron-large")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: Self.iconHeight)
                .foregroundColor(.srgGrayC7)
                .opacity(0.8)
                .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
        } label: {
            Color.clear
        }
        #else
        Image("chevron-large")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: Self.iconHeight)
            .foregroundColor(.srgGrayC7)
            .opacity(0.8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .background(Color.white.opacity(0.1))
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
            .frame(maxHeight: .infinity, alignment: .top)
        #endif
    }
    
    #if os(tvOS)
    private func action() {
        navigateToSection(section, filter: filter)
    }
    #endif
}

// MARK: Accessibility

private extension MoreCell {
    var accessibilityLabel: String? {
        return PlaySRGAccessibilityLocalizedString("More", comment: "More button label")
    }
    
    var accessibilityHint: String? {
        return PlaySRGAccessibilityLocalizedString("Opens details.", comment: "More button hint")
    }
}

// MARK: Preview

struct MoreCell_Previews: PreviewProvider {
    static var previews: some View {
        MoreCell(section: .configured(.tvLive), filter: nil)
            .previewLayout(.fixed(width: 400, height: 400))
    }
}
