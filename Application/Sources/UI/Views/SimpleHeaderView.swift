//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-hug
struct SimpleHeaderView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .srgFont(.H3)
            .lineLimit(1)
            .foregroundColor(.srgGrayC7)
            .padding(.vertical, constant(iOS: 3, tvOS: 15))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(label: title.lowercased(), traits: .isHeader)
    }
}

// MARK: Size

final class SimpleHeaderViewSize: NSObject {
    @objc static func recommended(title: String?, layoutWidth: CGFloat) -> NSCollectionLayoutSize {
        if let title = title, !title.isEmpty {
            let hostController = UIHostingController(rootView: SimpleHeaderView(title: title))
            let size = hostController.sizeThatFits(in: CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height))
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(size.height))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
        }
    }
}

// MARK: Preview

struct SimpleHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SimpleHeaderView(title: "Section title")
            SimpleHeaderView(title: .loremIpsum)
        }
        .frame(width: 800)
        .previewLayout(.sizeThatFits)
    }
}
