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
    private static func nextPlaybackRate(for controller: SRGLetterboxController) -> Float? {
        let supportedPlaybackRates = controller.supportedPlaybackRates
        guard !supportedPlaybackRates.isEmpty else { return nil }
        
        if let index = supportedPlaybackRates.firstIndex(where: { $0.floatValue == controller.playbackRate }),
           index < supportedPlaybackRates.count - 1 {
            return supportedPlaybackRates[index + 1].floatValue
        }
        else {
            return supportedPlaybackRates.first?.floatValue
        }
    }
    
    private var playbackRateButton: CPNowPlayingButton {
        return CPNowPlayingPlaybackRateButton { _ in
            guard let controller = SRGLetterboxService.shared.controller,
                  let nextPlaybackRate = Self.nextPlaybackRate(for: controller) else { return }
            controller.playbackRate = nextPlaybackRate
        }
    }
    
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
        nowPlayingTemplate.updateNowPlayingButtons([playbackRateButton])
        
        pushTemplate(nowPlayingTemplate, animated: true) { _, _ in
            completion()
        }
    }
}
