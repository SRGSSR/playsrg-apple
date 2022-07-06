//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-hug
struct TransluscentHeaderView: View {
    let title: String
    let horizontalPadding: CGFloat
    
    var body: some View {
        Text(title)
            .srgFont(.H3)
            .lineLimit(1)
            .foregroundColor(.srgGrayC7)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, constant(iOS: 3, tvOS: 15))
            .frame(maxWidth: .infinity, alignment: .leading)
            .transluscentBackground()
            .accessibilityElement(label: title.lowercased(), traits: .isHeader)
    }
}

// MARK: Helpers

private extension View {
    func transluscentBackground() -> some View {
#if os(iOS)
        Group {
            if #available(iOS 15, *) {
                background(.thinMaterial)
            }
            else {
                background(Blur(style: .systemThinMaterial))
            }
        }
#else
        return background(Color.clear)
#endif
    }
}

// MARK: Size

enum TransluscentHeaderViewSize {
    static func recommended(title: String?, horizontalPadding: CGFloat, layoutWidth: CGFloat) -> NSCollectionLayoutSize {
        if let title, !title.isEmpty {
            let hostController = UIHostingController(rootView: TransluscentHeaderView(title: title, horizontalPadding: horizontalPadding))
            let size = hostController.sizeThatFits(in: CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height))
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(size.height))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
        }
    }
}

// MARK: Preview

struct TransluscentHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TransluscentHeaderView(title: "Section title", horizontalPadding: 4)
            TransluscentHeaderView(title: .loremIpsum, horizontalPadding: 16)
        }
        .frame(width: 800)
        .previewLayout(.sizeThatFits)
    }
}
