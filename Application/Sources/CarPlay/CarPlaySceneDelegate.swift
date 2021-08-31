//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import CarPlay
import SRGLetterbox

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?
    private var model = RadioLiveStreamsViewModel()
    private var cancellables = Set<AnyCancellable>()
    let radioLiveStreamsListTemplate: CPListTemplate = CPListTemplate(title: NSLocalizedString("Livestreams", comment: "Livestreams tab title"), sections: [])
    let letterboxController = SRGLetterboxController()

    // MARK: - Custom Functions
    func updateRadioLiveStreams(medias: [SRGMedia]) {
        
        var items: [CPListItem] = []

        for media in medias {
            let listItem = CPListItem(text: title(media: media), detailText: subtitle(media: media), image: logoImage(media: media))
            listItem.accessoryType = .disclosureIndicator
            listItem.handler = { [weak self] item, completion in
                guard let strongSelf = self else { return }
                print(media.urn)
                
                // Play letterbox
                SRGLetterboxService.shared.controller?.playURN(media.urn, at: .none, withPreferredSettings: .none)
                
                // Create now playing template
                let nowPlayingTemplate = CPNowPlayingTemplate.shared
                strongSelf.interfaceController?.pushTemplate(nowPlayingTemplate, animated: true, completion: { _, _ in
                    completion()
                })
            }

            items.append(listItem)
        }
        let section = CPListSection(items: items)
        radioLiveStreamsListTemplate.updateSections([section])
    }
    
    // MARK: - CPTemplateApplicationScene
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        
        self.interfaceController = interfaceController
        
        // Get radio live streams
        model.$medias
            .sink { [weak self] medias in
                guard let strongSelf = self else { return }
                strongSelf.updateRadioLiveStreams(medias: medias)
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
    
    func channel(media: SRGMedia) -> SRGChannel? {
        guard let channel = media.channel else { return nil }
        return channel
    }
    
    func logoImage(media: SRGMedia) -> UIImage? {
        guard let channel = media.channel else { return nil }
        return channel.play_largeLogoImage
    }
    
    func title(media: SRGMedia) -> String? {
        guard let channel = media.channel else { return nil }
        print("channel.title", channel.title)
        print("MediaDescription.title(for: media, style: .date)", MediaDescription.title(for: media, style: .date))
        return channel.title
    }
    
    func subtitle(media: SRGMedia) -> String? {
        if media.contentType == .scheduledLivestream {
            return MediaDescription.subtitle(for: media, style: .date)
        }
        return nil
    }
    
}

