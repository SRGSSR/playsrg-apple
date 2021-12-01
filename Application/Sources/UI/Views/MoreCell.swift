//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct MoreCell: View {
    let section: Content.Section
    let imageType: SRGImageType
    let filter: SectionFiltering?
    
    static let iconHeight: CGFloat = constant(iOS: 60, tvOS: 100)
    
    fileprivate static func aspectRatio(for imageType: SRGImageType) -> CGFloat {
        return imageType == .showPoster ? 2 / 3 : 16 / 9
    }
    
    var body: some View {
#if os(tvOS)
        LabeledCardButton(aspectRatio: Self.aspectRatio(for: imageType), action: action) {
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
            .aspectRatio(Self.aspectRatio(for: imageType), contentMode: .fit)
            .background(Color.placeholder)
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
        MoreCell(section: .configured(.tvLive), imageType: .default, filter: nil)
            .previewLayout(.fixed(width: 400, height: 400))
    }
}
