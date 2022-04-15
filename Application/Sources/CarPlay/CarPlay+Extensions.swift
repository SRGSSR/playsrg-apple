//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay

extension CPListTemplate {
    static func list(_ list: CarPlayList, interfaceController: CPInterfaceController) -> CPListTemplate {
        let template = CPListTemplate(title: list.title, sections: [])
        template.controller = CarPlayTemplateListController(list: list, template: template, interfaceController: interfaceController)
        return template
    }
    
    static var playbackRate: CPListTemplate {
        let template = CPListTemplate(title: NSLocalizedString("Playback speed", comment: "Playback speed screen title"), sections: [])
        template.controller = CarPlayPlaybackSpeedController(template: template)
        return template
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
        pushTemplate(nowPlayingTemplate, animated: true) { _, _ in
            completion()
        }
    }
}
