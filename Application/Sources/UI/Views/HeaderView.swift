//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-hug
struct HeaderView: View {
    let title: String
    let subtitle: String?
    let hasDetailDisclosure: Bool
    let primaryColor: Color
    
    @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass
    @Environment(\.sizeCategory) private var sizeCategory
    
    init(title: String, subtitle: String?, hasDetailDisclosure: Bool, primaryColor: Color = .srgGrayD2) {
        self.title = title
        self.subtitle = subtitle
        self.hasDetailDisclosure = hasDetailDisclosure
        self.primaryColor = primaryColor
    }
    
    private var displayableSubtitle: String? {
        if horizontalSizeClass == .regular, let subtitle, !subtitle.isEmpty {
            return subtitle
        }
        else {
            return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(title)
                    .srgFont(.H3)
                    .lineLimit(1)
                if hasDetailDisclosure {
                    Image(.chevron)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: SRGFont.metricsForFont(with: .H3).scaledValue(for: 18))
                        .padding(.horizontal, 2)
                }
            }
            if let subtitle = displayableSubtitle {
                Text(subtitle)
                    .srgFont(.subtitle1)
                    .lineLimit(1)
            }
        }
        .foregroundColor(primaryColor)
        .padding(.vertical, constant(iOS: 3, tvOS: 15))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(label: title, traits: .isHeader)
    }
}

// MARK: Size

enum HeaderViewSize {
    static func recommended(forTitle title: String?, subtitle: String?, layoutWidth: CGFloat) -> NSCollectionLayoutSize {
        if let title, !title.isEmpty {
            let hostController = UIHostingController(rootView: HeaderView(title: title, subtitle: subtitle, hasDetailDisclosure: true))
            let size = hostController.sizeThatFits(in: CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height))
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(size.height))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
        }
    }
}

// MARK: Preview

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HeaderView(title: "Title", subtitle: nil, hasDetailDisclosure: false)
            HeaderView(title: "Title", subtitle: nil, hasDetailDisclosure: true)
            HeaderView(title: "Title", subtitle: nil, hasDetailDisclosure: true, primaryColor: .white)
            HeaderView(title: "Title", subtitle: "Subtitle", hasDetailDisclosure: false)
            HeaderView(title: "Title", subtitle: "Subtitle", hasDetailDisclosure: true)
            HeaderView(title: "Title", subtitle: "Subtitle", hasDetailDisclosure: true, primaryColor: .white)
            HeaderView(title: .loremIpsum, subtitle: .loremIpsum, hasDetailDisclosure: false)
            HeaderView(title: .loremIpsum, subtitle: .loremIpsum, hasDetailDisclosure: true)
            HeaderView(title: .loremIpsum, subtitle: .loremIpsum, hasDetailDisclosure: true, primaryColor: .white)
        }
        .frame(width: 800)
        .previewLayout(.sizeThatFits)
    }
}
