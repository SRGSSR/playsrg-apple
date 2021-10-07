//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay

private var controllerKey: Void?

extension CPTemplate {
    /**
     *  Associate a controller object to the template, with matching lifetime.
     */
    var controller: Any? {
        get {
            objc_getAssociatedObject(self, &controllerKey)
        }
        set {
            objc_setAssociatedObject(self, &controllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension CPListTemplate {
    convenience init(list: CarPlayList, interfaceController: CPInterfaceController) {
        self.init(title: list.title, sections: [])
        controller = CarPlayTemplateListController(list: list, template: self, interfaceController: interfaceController)
    }
}

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
