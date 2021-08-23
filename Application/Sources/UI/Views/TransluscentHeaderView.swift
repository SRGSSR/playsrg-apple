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
            .background(BackgroundView())
            .accessibilityElement(label: title.lowercased(), traits: .isHeader)
    }
    
    /// Behavior: h-exp, v-exp
    // TODO: Use native blur API on iOS 15 (see https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-visual-effect-blurs)
    struct BackgroundView: View {
        var body: some View {
            #if os(iOS)
            Blur(style: .systemThinMaterial)
            #else
            Color.clear
            #endif
        }
    }
}

// MARK: Size

final class TransluscentHeaderViewSize: NSObject {
    @objc static func recommended(title: String?, horizontalPadding: CGFloat, layoutWidth: CGFloat) -> NSCollectionLayoutSize {
        if let title = title, !title.isEmpty {
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
