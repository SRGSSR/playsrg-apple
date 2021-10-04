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
    private var cancellables = Set<AnyCancellable>()
    let radioLiveStreamsListTemplate: CPListTemplate = CPListTemplate(title: NSLocalizedString("Livestreams", comment: "Livestreams tab title"), sections: [])
    let favoriteEpisodesStreamsListTemplate: CPListTemplate = CPListTemplate(title: NSLocalizedString("Favorites", comment: "Favorites tab title"), sections: [])
    let trendsListTemplate: CPListTemplate = CPListTemplate(title: NSLocalizedString("Tendances", comment: ""), sections: [])
    let latestTrendsByRadioListTemplate: CPListTemplate = CPListTemplate(title: NSLocalizedString("Tendances", comment: ""), sections: [])

}

// MARK: - CPTemplateApplicationSceneDelegate

extension CarPlaySceneDelegate: CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        
        self.interfaceController = interfaceController
        
        // Configure Live Tab
        getRadioLiveStreams()
        
        // Configure Favorite Tab
        getFavoriteEpisodes()
        
        // Configure Trends Tab
        getTrends()
        
        // Create a tab bar
        radioLiveStreamsListTemplate.tabImage = UIImage(named: "livestreams_tab")
        favoriteEpisodesStreamsListTemplate.tabImage = UIImage(named: "favorite")
        trendsListTemplate.tabImage = UIImage(named: "favorite")

        let tabBar = CPTabBarTemplate.init(templates: [radioLiveStreamsListTemplate, favoriteEpisodesStreamsListTemplate, trendsListTemplate])
        tabBar.delegate = self
        self.interfaceController?.delegate = self
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
        
        if aTemplate == latestTrendsByRadioListTemplate {
            latestTrendsByRadioListTemplate.updateSections([])
        }
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
        let radiosViewModel = RadiosViewModel(with: .all)
        radiosViewModel.$medias
            .sink { [weak self] medias in
                guard let self = self else { return }
                self.updateRadioLiveStreams(medias: medias)
            }
            .store(in: &cancellables)
    }
    
    func getFavoriteEpisodes() {
        let favoriteEpisodesViewModel = FavoriteEpisodesViewModel()
        favoriteEpisodesViewModel.$medias
            .sink { [weak self] medias in
                guard let self = self else { return }
                self.updateFavoriteEpisodes(medias: medias)
            }
            .store(in: &cancellables)
    }
    
    func getTrends() {
        let radiosViewModel = RadiosViewModel(with: .default)
        radiosViewModel.$medias
            .sink { [weak self] medias in
                guard let self = self else { return }
                self.updateTrends(medias: medias)
            }
            .store(in: &cancellables)
    }
    
    func getTrendsByRadio(channelUid: String) {
        let latestTrendsByRadioViewModel = LatestTrendsByRadioViewModel(for: channelUid)
        latestTrendsByRadioViewModel.$medias
            .sink { [weak self] medias in
                guard let self = self else { return }
                self.updateTrendsByRadio(medias: medias)
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
                self.playMedia(media: media, completion: completion)
            }
            items.append(listItem)
        }
        let section = CPListSection(items: items)
        radioLiveStreamsListTemplate.updateSections([section])
    }
    
    func updateFavoriteEpisodes(medias: [FavoriteEpisodesViewModel.MediaData]) {

        var items: [CPListItem] = []

        for mediaData in medias {

            var title = ""
            if let show = mediaData.media.show {
                title = show.title
            }
            if let channel = mediaData.media.channel {
                title = "\(title) - \(channel.title)"
            }

            let detailText = (DateFormatter.play_relativeShort.string(from: mediaData.media.date))
            let listItem = CPListItem(text: title, detailText: detailText, image: mediaData.image)
            listItem.accessoryType = .disclosureIndicator
            listItem.handler = { [weak self] _, completion in
                guard let self = self else { return }
                self.playMedia(media: mediaData.media, completion: completion)
            }
            items.append(listItem)
        }
        let section = CPListSection(items: items)
        favoriteEpisodesStreamsListTemplate.updateSections([section])
    }
    
    func updateTrends(medias: [SRGMedia]) {
        
        var items: [CPListItem] = []
        
        for media in medias {
            let listItem = CPListItem(text: title(media: media), detailText: subtitle(media: media), image: logoImage(media: media))
            listItem.accessoryType = .disclosureIndicator
            listItem.handler = { [weak self] _, completion in
                guard let self = self, let channelUid = media.channel?.uid else { return }
                self.displayLatestTrendsByRadio(channelUid: channelUid, completion: completion)
            }
            items.append(listItem)
        }
        let section = CPListSection(items: items)
        trendsListTemplate.updateSections([section])
    }
    
    func updateTrendsByRadio(medias: [LatestTrendsByRadioViewModel.MediaData]) {
        var items: [CPListItem] = []
        
        for mediaData in medias {

            var title = ""
            if let show = mediaData.media.show {
                title = show.title
            }

            let detailText = (DateFormatter.play_relativeShort.string(from: mediaData.media.date))
            let listItem = CPListItem(text: title, detailText: detailText, image: mediaData.image)
            listItem.accessoryType = .disclosureIndicator
            listItem.handler = { [weak self] _, completion in
                guard let self = self else { return }
                self.playMedia(media: mediaData.media, completion: completion)
            }
            items.append(listItem)
        }
        let section = CPListSection(items: items)
        latestTrendsByRadioListTemplate.updateSections([section])
    }
    
    func displayLatestTrendsByRadio(channelUid: String, completion: @escaping () -> Void) {
                
        // Configure Trends Tab by radio
        self.getTrendsByRadio(channelUid: channelUid)
        
        // Display
        self.interfaceController?.pushTemplate(latestTrendsByRadioListTemplate, animated: true, completion: { [weak self] _, _ in
            guard let self = self else { return }
            completion()
        })
    }
}

// MARK: - Now Playing

extension CarPlaySceneDelegate {
    
    func playMedia(media: SRGMedia, completion: @escaping () -> Void) {
        
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
    
}
