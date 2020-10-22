//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

func navigateToMedia(media: SRGMedia, play: Bool = false) {
    if let topViewController = UIApplication.shared.windows.first?.topViewController {
        if !play && media.contentType != .livestream {
            let hostController = UIHostingController(rootView: MediaDetailView(media: media))
            topViewController.present(hostController, animated: true, completion: nil)
        }
        else {
            let letterboxViewController = SRGLetterboxViewController()
            letterboxViewController.controller.playMedia(media, at: nil, withPreferredSettings: nil)
            topViewController.present(letterboxViewController, animated: true, completion: nil)
        }
    }
}
