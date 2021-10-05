//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import CarPlay
import SRGLetterbox

final class CarPlaySceneDelegate: UIResponder {
    var interfaceController: CPInterfaceController?
}

extension CarPlaySceneDelegate: CPTemplateApplicationSceneDelegate {
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        let livestreamsTemplate = CarPlayListTemplate.template(list: .livestreams(contentProviders: .all, action: .play), interfaceController: interfaceController)
        livestreamsTemplate.tabTitle = NSLocalizedString("Livestreams", comment: "Livestreams tab title")
        livestreamsTemplate.tabImage = UIImage(named: "livestreams_tab")
        
        let favoriteEpisodesTemplate = CarPlayListTemplate.template(list: .latestEpisodesFromFavorites, interfaceController: interfaceController)
        favoriteEpisodesTemplate.tabTitle = NSLocalizedString("Favorites", comment: "Favorites tab title")
        favoriteEpisodesTemplate.tabImage = UIImage(named: "favorite")
        
        let mostPopularTemplate = CarPlayListTemplate.template(list: .livestreams(contentProviders: .default, action: .displayMostPopular), interfaceController: interfaceController)
        mostPopularTemplate.tabTitle = NSLocalizedString("Trends", comment: "Trends tab title")
        mostPopularTemplate.tabImage = UIImage(named: "favorite")
        
        let tabBarTemplate = CPTabBarTemplate(templates: [livestreamsTemplate, favoriteEpisodesTemplate, mostPopularTemplate])
        self.interfaceController?.setRootTemplate(tabBarTemplate, animated: true, completion: nil)
    }
    
    private func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
}
