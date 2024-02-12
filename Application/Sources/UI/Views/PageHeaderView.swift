//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct PageHeaderView: View {
    let title: String?
    let summary: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title {
                HStack(spacing: 0) {
                    Text(title)
                        .srgFont(.H1)
                        .foregroundColor(.srgGrayC7)
                    // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                    // when calculated with a `UIHostingController`, but without this the text does not occupy
                    // all lines it could.
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            if let summary {
                Text(summary)
                    .srgFont(.body)
                    .foregroundColor(.srgGrayC7)
                // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                // when calculated with a `UIHostingController`, but without this the text does not occupy
                // all lines it could.
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 12)
    }
}

// MARK: Size

enum PageHeaderViewSize {
    static func recommended(forTitle title: String?, summary: String?, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if let title, !title.isEmpty {
            let fittingSize = CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height)
            let size = PageHeaderView(title: title, summary: summary).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
            return NSCollectionLayoutSize(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
        }
    }
}

// MARK: Preview

struct PageHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PageHeaderView(title: "Title", summary: nil)
            PageHeaderView(title: "Title", summary: "Description")
            PageHeaderView(title: .loremIpsum, summary: nil)
            PageHeaderView(title: .loremIpsum, summary: .loremIpsum)
            PageHeaderView(title: nil, summary: nil)
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 1000)
        .environment(\.horizontalSizeClass, .regular)
        
        Group {
            PageHeaderView(title: "Title", summary: nil)
            PageHeaderView(title: "Title", summary: "Description")
            PageHeaderView(title: .loremIpsum, summary: nil)
            PageHeaderView(title: .loremIpsum, summary: .loremIpsum)
            PageHeaderView(title: nil, summary: nil)
        }
        .frame(width: 375)
        .previewLayout(.sizeThatFits)
        .environment(\.horizontalSizeClass, .compact)
    }
}
