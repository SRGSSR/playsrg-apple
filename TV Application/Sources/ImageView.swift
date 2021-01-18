//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import FetchImage
import SwiftUI

struct ImageView: View {
    let url: URL?
    let contentMode: ContentMode
    
    init(url: URL?, contentMode: ContentMode = .fit) {
        self.url = url
        self.contentMode = contentMode
    }
    
    var body: some View {
        // Wrap into ZStack so that when no URL is provided we still have a view filling all available space
        ZStack {
            if let url = url {
                FetchView(url: url, contentMode: contentMode)
            }
        }
    }
    
    private struct FetchView: View {
        let contentMode: ContentMode
        
        @ObservedObject var fetchImage: FetchImage
        
        // Use separate state so that we can track image loading and only animate such changes. Initially set to `true`
        // since we fetch the image at initialization time.
        @State var isLoading: Bool = true
        
        init(url: URL, contentMode: ContentMode) {
            fetchImage = FetchImage(url: url)
            self.contentMode = contentMode
            fetchImage.fetch()
        }
        
        private func optimalContentMode(for size: CGSize) -> ContentMode {
            guard contentMode == .fit,
                  let imageSize = fetchImage.image?.size else { return contentMode }
            
            let tolerance = CGFloat(0.01)
            
            // Calculate the size of the fitted image in the provided size. If matching up to a given tolerance,
            // then apply filling behavior instead to have a perfect fit (thus entirely hiding the image background)
            // while only slightly stretching the image.
            if size.width > size.height {
                let resizedImageHeight = imageSize.height * size.width / imageSize.width
                return (resizedImageHeight - size.height).magnitude / size.height < tolerance ? .fill : .fit
            }
            else {
                let resizedImageWidth = imageSize.width * size.height / imageSize.height
                return (resizedImageWidth - size.width).magnitude / size.width < tolerance ? .fill : .fit
            }
        }
        
        public var body: some View {
            GeometryReader { geometry in
                fetchImage.view?
                    .resizable()
                    .aspectRatio(contentMode: optimalContentMode(for: geometry.size))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .onReceive(fetchImage.$isLoading) { loading in
                        // Use async dispatch to avoid animation glitches
                        DispatchQueue.main.async {
                            withAnimation {
                                isLoading = loading
                            }
                        }
                    }
                    .onAppear(perform: fetchImage.fetch)
                    .onDisappear(perform: fetchImage.cancel)
                    .opacity(isLoading ? 0 : 1)
            }
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ImageView(url: URL(string: "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/450")!)
                .previewLayout(PreviewLayout.sizeThatFits)
                .previewDisplayName("Intrinsic size")
            
            ImageView(url: URL(string: "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/450")!)
                .previewLayout(.fixed(width: 600, height: 600))
                .previewDisplayName("600x600, fit")
            
            ImageView(url: URL(string: "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/450")!, contentMode: .fill)
                .previewLayout(.fixed(width: 600, height: 600))
                .previewDisplayName("600x600, fill")
        }
    }
}

