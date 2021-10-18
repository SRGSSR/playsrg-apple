//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay

// MARK: Class

final class CarPlaySceneDelegate: UIResponder {
    var interfaceController: CPInterfaceController?
}

// MARK: Protocols

extension CarPlaySceneDelegate: CPTemplateApplicationSceneDelegate {
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        interfaceController.delegate = self
        self.interfaceController = interfaceController
        
        let traitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
        var templates = [CPTemplate]()
        
        let livestreamsTemplate = CPListTemplate(list: .livestreams, interfaceController: interfaceController)
        livestreamsTemplate.tabImage = UIImage(named: "livestreams_tab", in: nil, compatibleWith: traitCollection)
        templates.append(livestreamsTemplate)
        
        let favoriteEpisodesTemplate = CPListTemplate(list: .latestEpisodesFromFavorites, interfaceController: interfaceController)
        favoriteEpisodesTemplate.tabImage = UIImage(named: "favorites_tab", in: nil, compatibleWith: traitCollection)
        templates.append(favoriteEpisodesTemplate)
        
        #if DEBUG || NIGHTLY
        let mostPopularTemplate = CPListTemplate(list: .mostPopular, interfaceController: interfaceController)
        mostPopularTemplate.tabImage = UIImage(named: "trends_tab", in: nil, compatibleWith: traitCollection)
        templates.append(mostPopularTemplate)
        #endif
        
        let tabBarTemplate = CPTabBarTemplate(templates: templates)
        interfaceController.setRootTemplate(tabBarTemplate, animated: true, completion: nil)
    }
    
    private func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        interfaceController?.notifyWillEnterForeground()
    }
}

extension CarPlaySceneDelegate: CPInterfaceControllerDelegate {
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        aTemplate.notifyWillAppear(animated: animated)
    }
    
    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        aTemplate.notifyDidAppear(animated: animated)
    }
    
    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        aTemplate.notifyWillDisappear(animated: animated)
    }
    
    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        aTemplate.notifyDidDisappear(animated: animated)
    }
}
