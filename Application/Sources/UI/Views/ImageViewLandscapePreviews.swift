//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ImageViewLandscapeCommon_Previews: PreviewProvider {
    private static let source = "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/400"
    
    static var previews: some View {
        Group {
            ImageView(source: source, contentMode: .aspectFit)
                .previewDisplayName(".aspectFit")
            ImageView(source: source, contentMode: .aspectFill)
                .previewDisplayName(".aspectFill")
            ImageView(source: source, contentMode: .center)
                .previewDisplayName(".center")
            ImageView(source: source, contentMode: .fill)
                .previewDisplayName(".fill")
        }
        .previewLayout(.fixed(width: 1000, height: 1000))
    }
}

struct ImageViewLandscapeAlignment_Previews: PreviewProvider {
    private static let source = "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/400"
    
    static var previews: some View {
        Group {
            ImageView(source: source, contentMode: .top)
                .previewDisplayName(".top")
            ImageView(source: source, contentMode: .bottom)
                .previewDisplayName(".bottom")
            ImageView(source: source, contentMode: .left)
                .previewDisplayName(".left")
            ImageView(source: source, contentMode: .right)
                .previewDisplayName(".right")
            ImageView(source: source, contentMode: .topLeft)
                .previewDisplayName(".topLeft")
            ImageView(source: source, contentMode: .topRight)
                .previewDisplayName(".topRight")
            ImageView(source: source, contentMode: .bottomLeft)
                .previewDisplayName(".bottomLeft")
            ImageView(source: source, contentMode: .bottomRight)
                .previewDisplayName(".bottomRight")
        }
        .previewLayout(.fixed(width: 1000, height: 1000))
    }
}

struct ImageViewLandscapeAspectFit_Previews: PreviewProvider {
    private static let source = "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/400"
    
    static var previews: some View {
        Group {
            ImageView(source: source, contentMode: .aspectFitTop)
                .previewDisplayName(".aspectFitTop")
            ImageView(source: source, contentMode: .aspectFitBottom)
                .previewDisplayName(".aspectFitBottom")
            ImageView(source: source, contentMode: .aspectFitLeft)
                .previewDisplayName(".aspectFitLeft")
            ImageView(source: source, contentMode: .aspectFitRight)
                .previewDisplayName(".aspectFitRight")
            ImageView(source: source, contentMode: .aspectFitTopLeft)
                .previewDisplayName(".aspectFitTopLeft")
            ImageView(source: source, contentMode: .aspectFitTopRight)
                .previewDisplayName(".aspectFitTopRight")
            ImageView(source: source, contentMode: .aspectFitBottomLeft)
                .previewDisplayName(".aspectFitBottomLeft")
            ImageView(source: source, contentMode: .aspectFitBottomRight)
                .previewDisplayName(".aspectFitBottomRight")
        }
        .previewLayout(.fixed(width: 1000, height: 1000))
    }
}

struct ImageViewLandscapeAspectFill_Previews: PreviewProvider {
    private static let source = "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/400"
    
    static var previews: some View {
        Group {
            ImageView(source: source, contentMode: .aspectFillTop)
                .previewDisplayName(".aspectFillTop")
            ImageView(source: source, contentMode: .aspectFillBottom)
                .previewDisplayName(".aspectFillBottom")
            ImageView(source: source, contentMode: .aspectFillLeft)
                .previewDisplayName(".aspectFillLeft")
            ImageView(source: source, contentMode: .aspectFillRight)
                .previewDisplayName(".aspectFillRight")
            ImageView(source: source, contentMode: .aspectFillTopLeft)
                .previewDisplayName(".aspectFillTopLeft")
            ImageView(source: source, contentMode: .aspectFillTopRight)
                .previewDisplayName(".aspectFillTopRight")
            ImageView(source: source, contentMode: .aspectFillBottomLeft)
                .previewDisplayName(".aspectFillBottomLeft")
            ImageView(source: source, contentMode: .aspectFillBottomRight)
                .previewDisplayName(".aspectFillBottomRight")
        }
        .previewLayout(.fixed(width: 1000, height: 1000))
    }
}
