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
    #if os(tvOS)
    private static let recommendedHeight: CGFloat = 150
    #else
    private static let recommendedHeight: CGFloat = 150
    #endif
    
    @objc static func recommended(text: String?, layoutWidth: CGFloat) -> CGSize {
        if let text = text, !text.isEmpty {
            return CGSize(width: layoutWidth, height: recommendedHeight)
        }
        else {
            return CGSize(width: layoutWidth, height: 0)
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
