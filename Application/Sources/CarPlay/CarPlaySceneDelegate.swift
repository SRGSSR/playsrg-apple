//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import CarPlay
import SRGLetterbox

class CarPlaySceneDelegate: UIResponder {
    
    var interfaceController: CPInterfaceController?
    private var model = RadioLiveStreamsViewModel()
    private var cancellables = Set<AnyCancellable>()
    let radioLiveStreamsListTemplate: CPListTemplate = CPListTemplate(title: NSLocalizedString("Livestreams", comment: "Livestreams tab title"), sections: [])
    
    // MARK: - Custom Functions
    func updateRadioLiveStreams(medias: [SRGMedia]) {
        
        var items: [CPListItem] = []
        
        for media in medias {
            let listItem = CPListItem(text: title(media: media), detailText: subtitle(media: media), image: logoImage(media: media))
            listItem.accessoryType = .disclosureIndicator
            listItem.handler = { [weak self] _, completion in
                guard let self = self else { return }
                
                // Play letterbox
                if let controller = SRGLetterboxService.shared.controller {
                    controller.playMedia(media, at: nil, withPreferredSettings: nil)
                } else {
                    let controller = SRGLetterboxController()
                    controller.playMedia(media, at: nil, withPreferredSettings: nil)
                    SRGLetterboxService.shared.enable(with: controller, pictureInPictureDelegate: nil)
                }
                
                // Create now playing template
                let nowPlayingTemplate = CPNowPlayingTemplate.shared
                self.interfaceController?.pushTemplate(nowPlayingTemplate, animated: true, completion: { _, _ in
                    completion()
                })
            }
            
            items.append(listItem)
        }
        let section = CPListSection(items: items)
        radioLiveStreamsListTemplate.updateSections([section])
    }
    
}

// MARK : - CPTemplateApplicationSceneDelegate
extension CarPlaySceneDelegate : CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        
        self.interfaceController = interfaceController
        
        // Get radio live streams
        model.$medias
            .sink { [weak self] medias in
                guard let self = self else { return }
                self.updateRadioLiveStreams(medias: medias)
            }
            .store(in: &cancellables)
        
        // Create a tab bar
        radioLiveStreamsListTemplate.tabImage = UIImage(named: "livestreams_tab")
        let tabBar = CPTabBarTemplate.init(templates: [radioLiveStreamsListTemplate])
        self.interfaceController?.setRootTemplate(tabBar, animated: true, completion: {_, _ in })
    }
    
    // CarPlay disconnected
    private func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
}

// MARK: - Properties

extension CarPlaySceneDelegate {
    
    func logoImage(media: SRGMedia) -> UIImage? {
        guard let channel = media.channel, let radioChannel = ApplicationConfiguration.shared.radioChannel(forUid: channel.uid) else { return nil }
        return RadioChannelLogoImageWithTraitCollection(radioChannel, UITraitCollection(userInterfaceIdiom: .carPlay))
    }
    
    func title(media: SRGMedia) -> String? {
        guard let channel = media.channel else { return nil }
        return channel.title
    }
    
    func subtitle(media: SRGMedia) -> String? {
        if media.contentType == .scheduledLivestream {
            return MediaDescription.subtitle(for: media, style: .date)
        }
        return nil
    }
    
}
