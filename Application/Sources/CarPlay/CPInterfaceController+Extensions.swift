//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay

extension CPInterfaceController {
    func play(media: SRGMedia, completion: @escaping () -> Void) {
        if let controller = SRGLetterboxService.shared.controller {
            controller.playMedia(media, at: nil, withPreferredSettings: nil)
        }
        else {
            let controller = SRGLetterboxController()
            controller.playMedia(media, at: nil, withPreferredSettings: nil)
            SRGLetterboxService.shared.enable(with: controller, pictureInPictureDelegate: nil)
        }
        
        pushTemplate(CPNowPlayingTemplate.shared, animated: true) { _, _ in
            completion()
        }
    }
}
