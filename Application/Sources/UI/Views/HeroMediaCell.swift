//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct HeroMediaCell: View {
    let media: SRGMedia?
    let label: String?
    
    var body: some View {
        ZStack {
            MediaVisualView(media: media, scale: .large, contentMode: .fill)
            DescriptionView(media: media)
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        let media: SRGMedia?
        
        private var subtitle: String? {
            guard let media = media else { return nil }
            return MediaDescription.subtitle(for: media, style: .show)
        }
        
        private var title: String? {
            guard let media = media else { return nil }
            return MediaDescription.title(for: media, style: .show)
        }
        
        var body: some View {
            VStack {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .srgFont(.subtitle1)
                        .lineLimit(1)
                }
                if let title = title {
                    Text(title)
                        .srgFont(.H2)
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .padding(.bottom, 30)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: Size

final class HeroMediaCellSize: NSObject {
    @objc static func recommended(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        let aspectRatio: CGFloat = (horizontalSizeClass == .compact) ? 1 : 16 / 9
        let height = min(layoutWidth * aspectRatio, 400)
        return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(height))
    }
}

// MARK: Preview

private extension View {
    func previewLayout(for layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> some View {
        let size = HeroMediaCellSize.recommended(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass).previewSize
        return previewLayout(.fixed(width: size.width, height: size.height))
            .horizontalSizeClass(horizontalSizeClass)
    }
}

struct HeroMediaCell_Previews: PreviewProvider {
    static var previews: some View {
        HeroMediaCell(media: Mock.media(), label: "New")
            .previewLayout(for: 375, horizontalSizeClass: .compact)
        HeroMediaCell(media: Mock.media(), label: "New")
            .previewLayout(for: 800, horizontalSizeClass: .regular)
    }
}
