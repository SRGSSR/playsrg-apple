//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/// Behavior: h-exp, v-exp
struct HeaderView: View {
    let title: String?
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title ?? String.placeholder(length: 8))
                .srgFont(.H2)
                .lineLimit(1)
            if let subtitle = subtitle {
                Text(subtitle)
                    .srgFont(.subtitle)
                    .lineLimit(1)
                    .opacity(0.8)
            }
        }
        .opacity(0.8)
        .redactedIfNil(title)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

class HeaderViewSize: NSObject {
    #if os(tvOS)
    static let smallHeight: CGFloat = 45
    static let tallHeight: CGFloat = 90
    #else
    static let smallHeight: CGFloat = 25
    static let tallHeight: CGFloat = 42
    #endif
    
    @objc static func recommended(title: String?, subtitle: String?, layoutWidth: CGFloat) -> CGSize {
        if let title = title, !title.isEmpty {
            if let subtitle = subtitle, !subtitle.isEmpty {
                return CGSize(width: layoutWidth, height: tallHeight)
            }
            else {
                return CGSize(width: layoutWidth, height: smallHeight)
            }
        }
        else {
            return CGSize(width: layoutWidth, height: 0)
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HeaderView(title: "Title", subtitle: nil)
            HeaderView(title: "Title", subtitle: "Subtitle")
            HeaderView(title: String.loremIpsum, subtitle: String.loremIpsum)
            HeaderView(title: nil, subtitle: nil)
        }
        .previewLayout(.fixed(width: 800, height: 200))
    }
}
