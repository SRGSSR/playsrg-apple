//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay

extension CPListTemplate {
    convenience init(list: CarPlayList, interfaceController: CPInterfaceController) {
        self.init(title: list.title, sections: [])
        controller = CarPlayTemplateListController(list: list, template: self, interfaceController: interfaceController)
    }
}

extension CPInterfaceController {
    func play(media: SRGMedia, completion: @escaping () -> Void) {
        if let controller = SRGLetterboxService.shared.controller {
            controller.playMedia(media, at: HistoryResumePlaybackPositionForMedia(media), withPreferredSettings: ApplicationSettingPlaybackSettings())
        }
        else {
            let controller = SRGLetterboxController()
            controller.playMedia(media, at: HistoryResumePlaybackPositionForMedia(media), withPreferredSettings: ApplicationSettingPlaybackSettings())
            SRGLetterboxService.shared.enable(with: controller, pictureInPictureDelegate: nil)
        }
        
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        nowPlayingTemplate.controller = CarPlayNowPlayingController()
        
        pushTemplate(nowPlayingTemplate, animated: true) { _, _ in
            completion()
        }
    }
}
