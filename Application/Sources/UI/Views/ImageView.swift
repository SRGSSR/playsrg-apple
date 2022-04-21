//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Nuke
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp (like `Image/resizable()`)
struct ImageView: UIViewRepresentable {
    let url: URL?
    let contentMode: ContentMode
    
    @Binding var isLoaded: Bool
    
    init(url: URL?, contentMode: ContentMode = constant(iOS: .fit, tvOS: .fill), isLoaded: Binding<Bool> = .constant(false)) {
        self.url = url
        self.contentMode = contentMode
        _isLoaded = isLoaded
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
            
            DispatchQueue.main.async {
                self.isLoaded = false
            }
            Nuke.loadImage(with: url, options: options, into: uiView) { result in
                if case .success = result {
                    DispatchQueue.main.async {
                        self.isLoaded = true
                    }
                }
            }
        }
        else {
            DispatchQueue.main.async {
                isLoaded = false
            }
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

// MARK: Preview

struct ImageView_Previews: PreviewProvider {
    private static let contentMode: ContentMode = .fill
    
    static var previews: some View {
        Group {
            ImageView(url: URL(string: "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/400")!)
            ImageView(url: URL(string: "https://www.rts.ch/2021/04/02/10/23/12095345.image/scale/width/400")!)
        }
        .aspectRatio(contentMode: .fit)
        .previewLayout(.fixed(width: 600, height: 600))
    }
}
