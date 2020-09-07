//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import FetchImage
import SwiftUI

struct ImageView: View {
    private struct FetchView: View {
        @ObservedObject var image: FetchImage
        let contentMode: ContentMode
        
        init(url: URL, contentMode: ContentMode) {
            image = FetchImage(url: url)
            self.contentMode = contentMode
        }

        public var body: some View {
            GeometryReader { geometry in
                image.view?
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .onAppear(perform: image.fetch)
                    .onDisappear(perform: image.cancel)
            }
        }
    }
    
    let url: URL?
    let contentMode: ContentMode
    
    init(url: URL?, contentMode: ContentMode = .fit) {
        self.url = url
        self.contentMode = contentMode
    }
    
    var body: some View {
        ZStack {
            if let url = url {
                FetchView(url: url, contentMode: contentMode)
            }
        }
        .animation(.default)
    }
}
