//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct HeroMediaCell: View {
    let media: SRGMedia?
    
    var body: some View {
        ZStack {
            MediaVisualView(media: media, scale: .small)
                .aspectRatio(HeroMediaCellSize.aspectRatio, contentMode: .fit)
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
            .padding(.bottom, 50)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: Size

final class HeroMediaCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    @objc static func recommended(layoutWidth: CGFloat) -> NSCollectionLayoutSize {
        return LayoutSwimlaneCellSize(layoutWidth, aspectRatio, 0)
    }
}

// MARK: Preview

struct HeroMediaCell_Previews: PreviewProvider {
    private static let size = HeroMediaCellSize.recommended(layoutWidth: 800).previewSize
    
    static var previews: some View {
        HeroMediaCell(media: Mock.media())
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
