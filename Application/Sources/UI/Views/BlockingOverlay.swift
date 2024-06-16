//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct BlockingOverlay: View {
    let media: SRGMedia?
    let messageDisplayed: Bool

    init(media: SRGMedia?, messageDisplayed: Bool = false) {
        self.media = media
        self.messageDisplayed = messageDisplayed
    }

    private var blockingReason: SRGBlockingReason? {
        media?.blockingReason(at: Date())
    }

    var body: some View {
        if let blockingReason, let blockingIconImage = UIImage.image(for: blockingReason) {
            ZStack {
                Color(white: 0, opacity: 0.6)
                VStack {
                    Image(uiImage: blockingIconImage)
                        .foregroundColor(.white)
                    if messageDisplayed, let message = SRGMessageForBlockedMediaWithBlockingReason(blockingReason) {
                        Text(message)
                            .srgFont(.H4)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .padding(8)
                    }
                }
            }
        }
    }
}

// MARK: Preview

struct BlockingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BlockingOverlay(media: Mock.media(.blocked))
                .background(Color.white)
                .previewLayout(.fixed(width: 300, height: 200))
            BlockingOverlay(media: Mock.media(.blocked), messageDisplayed: true)
                .background(Color.white)
                .previewLayout(.fixed(width: 300, height: 200))
        }
    }
}
