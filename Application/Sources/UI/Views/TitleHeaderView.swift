//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct TitleHeaderView: View {
    let title: String?
    let description: String?
    let titleTextAlignment: TextAlignment
    
    init(title: String?, description: String? = nil, titleTextAlignment: TextAlignment = .leading) {
        self.title = title
        self.description = description
        self.titleTextAlignment = titleTextAlignment
    }
    
    var foregroundColor: Color = .white
    
    func foregroundColor(_ color: Color) -> Self {
        var titleHeaderView = self
        
        titleHeaderView.foregroundColor = color
        return titleHeaderView
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title {
                HStack(spacing: 0) {
                    if titleTextAlignment != .leading {
                        Spacer(minLength: 0)
                    }
                    Text(title)
                        .srgFont(.H1)
                        .foregroundColor(foregroundColor)
                    // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                    // when calculated with a `UIHostingController`, but without this the text does not occupy
                    // all lines it could.
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(titleTextAlignment)
                    if titleTextAlignment != .trailing {
                        Spacer(minLength: 0)
                    }
                }
                if let description {
                    Text(description)
                        .srgFont(.body)
                        .foregroundColor(foregroundColor)
                    // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                    // when calculated with a `UIHostingController`, but without this the text does not occupy
                    // all lines it could.
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, constant(iOS: 16, tvOS: 0))
        .padding(.bottom, constant(iOS: 12, tvOS: 80))
    }
}

// MARK: Size

enum TitleHeaderViewSize {
    static func recommended(title: String?, description: String? = nil, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if let title {
            let fittingSize = CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height)
            let size = TitleHeaderView(title: title, description: description).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
            return NSCollectionLayoutSize(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
        }
    }
}

// MARK: Preview

struct TitleHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TitleHeaderView(title: "Title", description: "description")
            TitleHeaderView(title: .loremIpsum, description: .loremIpsum)
            TitleHeaderView(title: "Title", description: "description", titleTextAlignment: .center)
            TitleHeaderView(title: "Title", description: nil, titleTextAlignment: .center)
            TitleHeaderView(title: "Title", description: "description", titleTextAlignment: .trailing)
            TitleHeaderView(title: "Title", description: nil, titleTextAlignment: .trailing)
            TitleHeaderView(title: nil, description: nil)
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 1000)
        .environment(\.horizontalSizeClass, .regular)
        
        Group {
            TitleHeaderView(title: "Title", description: "description")
            TitleHeaderView(title: .loremIpsum, description: .loremIpsum)
            TitleHeaderView(title: "Title", description: "description", titleTextAlignment: .center)
            TitleHeaderView(title: "Title", description: nil, titleTextAlignment: .center)
            TitleHeaderView(title: "Title", description: "description", titleTextAlignment: .trailing)
            TitleHeaderView(title: "Title", description: nil, titleTextAlignment: .trailing)
            TitleHeaderView(title: nil, description: nil)
        }
        .frame(width: 375)
        .previewLayout(.sizeThatFits)
        .environment(\.horizontalSizeClass, .compact)
    }
}
