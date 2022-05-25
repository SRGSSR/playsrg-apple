//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct HighlightCell: View {
    let title: String
    let summary: String?
    let imageUrl: URL?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                ImageView(source: imageUrl, contentMode: .aspectFillTop)
                LinearGradient(gradient: Gradient(colors: [.srgGray16, .clear]), startPoint: .leading, endPoint: .center)
                DescriptionView(title: title, summary: summary)
                    .frame(width: geometry.size.width * 2 / 3, height: geometry.size.height)
            }
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        let title: String
        let summary: String?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text(title)
                    .srgFont(.H2)
                    .lineLimit(1)
                    .foregroundColor(.srgGrayC7)
                if let summary = summary {
                    Text(summary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .srgFont(.body)
                        .foregroundColor(.srgGray96)
                }
            }
            .padding(.leading, 60)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: Size

final class HighlightCellSize: NSObject {
    @objc static func fullWidth(title: String?, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if let title = title, !title.isEmpty {
            if horizontalSizeClass == .compact {
                return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(300))
            }
            else {
                return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(200))
            }
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(LayoutHeaderHeightZero))
        }
    }
}

// MARK: Preview

private extension View {
    func previewLayout(title: String?, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> some View {
        let size = HighlightCellSize.fullWidth(title: title, layoutWidth: 1000, horizontalSizeClass: horizontalSizeClass).previewSize
        return previewLayout(.fixed(width: size.width, height: size.height))
            .horizontalSizeClass(horizontalSizeClass)
    }
}

struct HighlightCell_Previews: PreviewProvider {
    static let title = "Title"
    
    static var previews: some View {
        HighlightCell(
            title: title,
            summary: "Summary",
            imageUrl: URL(string: "https://il.srgssr.ch/integrationlayer/2.0/image-scale-sixteen-to-nine/https://play-pac-public-production.s3.eu-central-1.amazonaws.com/images/4fe0346b-3b3b-47cf-b31a-9d4ae4e3552a.jpeg")!
        )
        .previewLayout(title: title, layoutWidth: 1000, horizontalSizeClass: .regular)
    }
}
