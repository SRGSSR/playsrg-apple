//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Nuke
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct ShowVisualView: View {
    let source: ImageRequestConvertible?
    let contentMode: ImageView.ContentMode
    
    init(source: ImageRequestConvertible?, contentMode: ImageView.ContentMode = .aspectFit) {
        self.source = source
        self.contentMode = contentMode
    }
    
    var body: some View {
        ImageView(source: source, contentMode: contentMode)
            .background(Color.black)
    }
}

// MARK: Preview

struct ShowVisualView_Previews: PreviewProvider {
    private static func showImageUrl(for show: SRGShow) -> URL? {
        return SRGDataProvider.current!.url(for: show.image, size: .medium)
    }
    
    static var previews: some View {
        Group {
            ShowVisualView(source: showImageUrl(for: Mock.show(.standard)))
            ShowVisualView(source: showImageUrl(for: Mock.show(.overflow)))
            ShowVisualView(source: showImageUrl(for: Mock.show(.short)))
        }
        .frame(width: 600, height: 500)
        .previewLayout(.sizeThatFits)
    }
}
