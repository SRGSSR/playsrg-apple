//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct ShowVisualView: View {
    let show: SRGShow?
    let size: SRGImageSize
    let imageVariant: SRGImageVariant
    let contentMode: ImageView.ContentMode

    init(
        show: SRGShow?,
        size: SRGImageSize,
        imageVariant: SRGImageVariant = .default,
        contentMode: ImageView.ContentMode = .aspectFit
    ) {
        self.show = show
        self.size = size
        self.imageVariant = imageVariant
        self.contentMode = contentMode
    }

    var body: some View {
        ImageView(source: imageUrl, contentMode: contentMode)
            .background(Color.thumbnailBackground)
    }

    private var imageUrl: URL? {
        switch imageVariant {
        case .poster:
            url(for: show?.posterImage, size: size)
        case .podcast:
            url(for: show?.podcastImage, size: size)
        case .default:
            url(for: show?.image, size: size)
        }
    }
}

// MARK: Preview

struct ShowVisualView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ShowVisualView(show: Mock.show(.standard), size: .small)
            ShowVisualView(show: Mock.show(.standard), size: .small, imageVariant: .poster)
            ShowVisualView(show: Mock.show(.overflow), size: .small)
            ShowVisualView(show: Mock.show(.short), size: .small)
        }
        .frame(width: 600, height: 500)
        .previewLayout(.sizeThatFits)
    }
}
