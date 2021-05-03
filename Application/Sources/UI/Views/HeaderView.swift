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
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    fileprivate static func displayableSubtitle(_ subtitle: String?, horizontalSizeClass: UIUserInterfaceSizeClass) -> String? {
        if horizontalSizeClass == .regular, let subtitle = subtitle, !subtitle.isEmpty {
            return subtitle
        }
        else {
            return nil
        }
    }
    
    private var displayableSubtitle: String? {
        #if os(iOS)
        return Self.displayableSubtitle(subtitle, horizontalSizeClass: UIUserInterfaceSizeClass(horizontalSizeClass))
        #else
        return Self.displayableSubtitle(subtitle, horizontalSizeClass: .regular)
        #endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title ?? String.placeholder(length: 8))
                .srgFont(.H2)
                .lineLimit(1)
            if let subtitle = displayableSubtitle {
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
    static let smallHeight: CGFloat = constant(iOS: 25, tvOS: 45)
    static let tallHeight: CGFloat = constant(iOS: 42, tvOS: 90)
    
    @objc static func recommended(title: String?, subtitle: String?, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> CGSize {
        if let title = title, !title.isEmpty {
            if HeaderView.displayableSubtitle(subtitle, horizontalSizeClass: horizontalSizeClass) != nil {
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
