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
        if let url = url {
            FetchView(url: url, contentMode: contentMode)
        }
    }
    
    private struct FetchView: View {
        let contentMode: ContentMode
        
        @ObservedObject var fetchImage: FetchImage
        
        // Use separate state so that we can track image loading and only animate such changes. Since FetchImage
        // immediately fetches the image the state is initially set to true.
        @State var isLoading: Bool = true
        
        init(url: URL, contentMode: ContentMode) {
            fetchImage = FetchImage(url: url)
            self.contentMode = contentMode
        }
        
        public var body: some View {
            GeometryReader { geometry in
                fetchImage.view?
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
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

