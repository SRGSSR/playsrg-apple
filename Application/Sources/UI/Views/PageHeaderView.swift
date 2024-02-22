//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct PageHeaderView: View {
    let page: SRGContentPage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = page?.title {
                HStack(spacing: 0) {
                    Text(title)
                        .srgFont(.H1)
                        .foregroundColor(.white)
                    // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                    // when calculated with a `UIHostingController`, but without this the text does not occupy
                    // all lines it could.
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            if let description = page?.summary {
                Text(description)
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
        .padding(.horizontal, constant(iOS: 16, tvOS: 0))
        .padding(.bottom, constant(iOS: 12, tvOS: 80))
    }
}

// MARK: Size

enum PageHeaderViewSize {
    static func recommended(for page: SRGContentPage?, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if let page {
            let fittingSize = CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height)
            let size = PageHeaderView(page: page).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
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
            PageHeaderView(page: Mock.page())
            PageHeaderView(page: Mock.page(.short))
            PageHeaderView(page: Mock.page(.overflow))
            PageHeaderView(page: nil)
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 1000)
        .environment(\.horizontalSizeClass, .regular)
        
        Group {
            PageHeaderView(page: Mock.page())
            PageHeaderView(page: Mock.page(.short))
            PageHeaderView(page: Mock.page(.overflow))
            PageHeaderView(page: nil)
        }
        .frame(width: 375)
        .previewLayout(.sizeThatFits)
        .environment(\.horizontalSizeClass, .compact)
    }
}
