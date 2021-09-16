//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import CarPlay
import SRGLetterbox
import YYWebImage

class CarPlaySceneDelegate: UIResponder {
    
    var interfaceController: CPInterfaceController?
    private var radioLiveStreamsModel = RadioLiveStreamsViewModel()
    private var favoriteEpisodesModel = FavoriteEpisodesViewModel()
    private var cancellables = Set<AnyCancellable>()
    let radioLiveStreamsListTemplate: CPListTemplate = CPListTemplate(title: NSLocalizedString("Livestreams", comment: "Livestreams tab title"), sections: [])
    let favoriteEpisodesStreamsListTemplate: CPListTemplate = CPListTemplate(title: NSLocalizedString("Favorites", comment: "Favorites tab title"), sections: [])
 
}

// MARK : - CPTemplateApplicationSceneDelegate

extension CarPlaySceneDelegate : CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        
        self.interfaceController = interfaceController
        
        // Get radio live streams
        getRadioLiveStreams()
        
        // Get favorite episodes
        getFavoriteEpisodes()
        
        // Create a tab bar
        radioLiveStreamsListTemplate.tabImage = UIImage(named: "livestreams_tab")
        favoriteEpisodesStreamsListTemplate.tabImage = UIImage(named: "favorite")
        let tabBar = CPTabBarTemplate.init(templates: [radioLiveStreamsListTemplate, favoriteEpisodesStreamsListTemplate])
        tabBar.delegate = self
        self.interfaceController?.setRootTemplate(tabBar, animated: true, completion: {_, _ in })
    }
    
    // CarPlay disconnected
    private func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
}

// MARK: - CPInterfaceControllerDelegate

extension CarPlaySceneDelegate: CPInterfaceControllerDelegate {

    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        print("templateWillAppear", aTemplate)
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        print("templateDidAppear", aTemplate)
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        print("templateWillDisappear", aTemplate)
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        print("templateDidDisappear", aTemplate)
    }
}

// MARK: - CPTabBarTemplateDelegate

extension CarPlaySceneDelegate: CPTabBarTemplateDelegate {
    
    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
        
        if selectedTemplate == favoriteEpisodesStreamsListTemplate {
            getFavoriteEpisodes()
        }
        
    }
}


// MARK: - Custom Properties

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

// MARK: - Update data

extension CarPlaySceneDelegate {
    
    func getRadioLiveStreams() {
        radioLiveStreamsModel.$medias
            .sink { [weak self] medias in
                guard let self = self else { return }
                self.updateRadioLiveStreams(medias: medias)
            }
            .store(in: &cancellables)
    }
    
    func getFavoriteEpisodes() {
        favoriteEpisodesModel.$medias
            .sink { [weak self] medias in
                guard let self = self else { return }
                self.updateFavoriteEpisode(medias: medias)
            }
            .store(in: &cancellables)
    }

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
    
    func updateFavoriteEpisode(medias: [SRGMedia]) {
        print("medias", medias)
        
        // TODO: need to be refactored
        var items: [CPListItem] = []
        
        for media in medias {
            
            var title = ""
            if let show = media.show {
                title = show.title
            }
            if let channel = media.channel {
                title = "\(title) - \(channel.title)"
            }
            
            let detailText = (DateFormatter.play_relativeShort.string(from: media.date))

            print("title", media.show?.title)
            print("imageUrl", media.imageUrl(for: .small))
            
            var image = UIImage()
            let webImageManager = YYWebImageManager.shared()
            if let cache = webImageManager.cache, let imageUrl = media.imageUrl(for: .small) {
                image = cache.getImageForKey(webImageManager.cacheKey(for: imageUrl)) ?? UIImage()
            }
            
            let listItem = CPListItem(text: title, detailText: detailText, image: image)
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
        favoriteEpisodesStreamsListTemplate.updateSections([section])
    }
}
