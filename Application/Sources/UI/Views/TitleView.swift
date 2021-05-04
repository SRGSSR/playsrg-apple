//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/// Behavior: h-exp, v-exp
struct TitleView: View {
    let text: String?
    
    var body: some View {
        Text(text ?? String.placeholder(length: 8))
            .srgFont(.H1)
            .foregroundColor(.white)
            .lineLimit(1)
            .opacity(0.8)
            .redactedIfNil(text)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

class TitleViewSize: NSObject {
    private static let recommendedHeight: CGFloat = constant(iOS: 60, tvOS: 100)
    
    @objc static func recommended(text: String?) -> NSCollectionLayoutSize {
        if let text = text, !text.isEmpty {
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(recommendedHeight))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(0))
        }
    }
}

struct TitleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TitleView(text: "Title")
            TitleView(text: String.loremIpsum)
            TitleView(text: nil)
        }
        .previewLayout(.fixed(width: 800, height: 200))
    }
}
