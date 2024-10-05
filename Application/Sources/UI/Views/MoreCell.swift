//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct MoreCell: View {
    let section: Content.Section
    let imageVariant: SRGImageVariant
    let filter: SectionFiltering?
    let preview: Content.Preview?

    static let iconHeight: CGFloat = constant(iOS: 60, tvOS: 100)

    fileprivate static func aspectRatio(for imageVariant: SRGImageVariant) -> CGFloat {
        switch imageVariant {
        case .poster:
            2 / 3
        case .podcast:
            1
        case .default:
            16 / 9
        }
    }

    var body: some View {
        #if os(tvOS)
            LabeledCardButton(aspectRatio: Self.aspectRatio(for: imageVariant), action: action) {
                Image(.chevronLarge)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Self.iconHeight)
                    .foregroundColor(.srgGrayD2)
                    .opacity(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.srgGray33)
                    .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
            } label: {
                Color.clear
            }
        #else
            Image(.chevronLarge)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: Self.iconHeight)
                .foregroundColor(.srgGrayD2)
                .opacity(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(Self.aspectRatio(for: imageVariant), contentMode: .fit)
                .cornerRadius(LayoutStandardViewCornerRadius)
                .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
                .frame(maxHeight: .infinity, alignment: .top)
        #endif
    }

    #if os(tvOS)
        private func action() {
            navigateToSection(section, published: preview?.published ?? true, filter: filter)
        }
    #endif
}

// MARK: Accessibility

private extension MoreCell {
    var accessibilityLabel: String? {
        PlaySRGAccessibilityLocalizedString("More", comment: "More button label")
    }

    var accessibilityHint: String? {
        PlaySRGAccessibilityLocalizedString("Opens details.", comment: "More button hint")
    }
}

// MARK: Preview

struct MoreCell_Previews: PreviewProvider {
    static var previews: some View {
        MoreCell(section: .configured(.tvLive), imageVariant: .default, filter: nil, preview: nil)
            .previewLayout(.fixed(width: 400, height: 400))
    }
}
