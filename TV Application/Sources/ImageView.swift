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
        
        init(url: URL) {
            image = FetchImage(url: url)
        }

        public var body: some View {
            image.view?
                .resizable()
                .aspectRatio(contentMode: .fit)
                .animation(.default)
                .onAppear(perform: image.fetch)
                .onDisappear(perform: image.cancel)
        }
    }
    
    let url: URL?
    
    var body: some View {
        ZStack {
            if let url = url {
                FetchView(url: url)
            }
        }
    }
}
