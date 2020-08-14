//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGLetterbox
import SwiftUI

struct PlayerView: View {
    let media: SRGMedia
    
    private struct LetterboxPlayerView: UIViewControllerRepresentable {
        let media: SRGMedia
        
        func makeUIViewController(context: Context) -> SRGLetterboxViewController {
            let letterboxViewController = SRGLetterboxViewController()
            letterboxViewController.controller.playMedia(media, at: nil, withPreferredSettings: nil)
            return letterboxViewController
        }
        
        func updateUIViewController(_ uiViewController: SRGLetterboxViewController, context: Context) {
            // No bindings
        }
    }
    
    var body: some View {
        LetterboxPlayerView(media: media)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all, edges: .all)
    }
}
