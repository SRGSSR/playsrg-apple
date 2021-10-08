//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import CarPlay
import SRGAnalytics
import SRGLetterbox

final class CarPlaySceneDelegate: UIResponder {
    var interfaceController: CPInterfaceController?
}

extension CarPlaySceneDelegate: CPTemplateApplicationSceneDelegate {
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        interfaceController.delegate = self
        self.interfaceController = interfaceController
        
        let traitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
        
        let livestreamsTemplate = CPListTemplate(list: .livestreams, interfaceController: interfaceController)
        livestreamsTemplate.tabImage = UIImage(named: "livestreams_tab", in: nil, compatibleWith: traitCollection)
        
        let favoriteEpisodesTemplate = CPListTemplate(list: .latestEpisodesFromFavorites, interfaceController: interfaceController)
        favoriteEpisodesTemplate.tabImage = UIImage(named: "favorite_tab", in: nil, compatibleWith: traitCollection)
        
        let mostPopularTemplate = CPListTemplate(list: .mostPopular, interfaceController: interfaceController)
        mostPopularTemplate.tabImage = UIImage(named: "trends_tab", in: nil, compatibleWith: traitCollection)
        
        let tabBarTemplate = CPTabBarTemplate(templates: [livestreamsTemplate, favoriteEpisodesTemplate, mostPopularTemplate])
        interfaceController.setRootTemplate(tabBarTemplate, animated: true, completion: nil)
    }
    
    private func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
}

extension CarPlaySceneDelegate: CPInterfaceControllerDelegate {
    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        SRGAnalyticsTracker.shared.trackPageView(for: aTemplate)
    }
}
