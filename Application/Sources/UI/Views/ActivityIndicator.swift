//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ActivityIndicator: View {
    var body: some View {
        LoadingImageView()
            .frame(width: 90, height: 90)
    }
    
    private struct LoadingImageView: UIViewRepresentable {
        func makeUIView(context: Context) -> UIImageView {
            return UIImageView.play_loadingImageView90(withTintColor: .play_lightGray)
        }
        
        func updateUIView(_ uiView: UIImageView, context: Context) {
            // No update logic required
        }
    }
}

struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator()
            .previewLayout(.sizeThatFits)
    }
}
