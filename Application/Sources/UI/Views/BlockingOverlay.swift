//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct BlockingOverlay: View {
    let media: SRGMedia?
    
    private var blockingIconImage: UIImage? {
        guard let blockingReason = media?.blockingReason(at: Date()) else { return nil }
        return UIImage.play_image(for: blockingReason)
    }
    
    var body: some View {
        if let blockingIconImage = blockingIconImage {
            ZStack {
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.6))
                Image(uiImage: blockingIconImage)
                    .foregroundColor(.white)
            }
        }
    }
}
