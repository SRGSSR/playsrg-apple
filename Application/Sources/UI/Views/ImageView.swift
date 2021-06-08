//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Nuke
import SwiftUI

/// Behavior: h-exp, v-exp (like `Image/resizable()`)
struct ImageView: UIViewRepresentable {
    let url: URL?
    let contentMode: ContentMode
    
    init(url: URL?, contentMode: ContentMode = constant(iOS: .fit, tvOS: .fill)) {
        self.url = url
        self.contentMode = contentMode
    }
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.applySizingBehavior(.expanding)
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.contentMode = Self.contentMode(contentMode)
        
        if let url = url {
            let options = ImageLoadingOptions(
                transition: .fadeIn(duration: 0.5)
            )
            Nuke.loadImage(with: url, options: options, into: uiView)
        }
        else {
            Nuke.cancelRequest(for: uiView)
            uiView.image = nil
        }
    }
    
    private static func contentMode(_ contentMode: ContentMode) -> UIView.ContentMode {
        switch contentMode {
        case .fit:
            return .scaleAspectFit
        case .fill:
            return .scaleAspectFill
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static let contentMode: ContentMode = .fill
    
    static var previews: some View {
        Group {
            ImageView(url: URL(string: "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/400")!)
            ImageView(url: URL(string: "https://www.rts.ch/2021/04/02/10/23/12095345.image/scale/width/400")!)
        }
        .aspectRatio(contentMode: .fit)
        .previewLayout(.fixed(width: 600, height: 600))
    }
}
