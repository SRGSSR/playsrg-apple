//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import CarPlay

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?
    private var radioLiveStreamsViewModel = RadioLiveStreamsViewModel()
    private var cancellables = Set<AnyCancellable>()
    let radioLiveStreamsListTemplate: CPListTemplate = CPListTemplate(title: "Châines radio", sections: [])
    let radioLiveStreamsGridTemplate: CPGridTemplate = CPGridTemplate(title: "Grid", gridButtons: [])

    // MARK: - Custom Functions
    func updateRadioLiveStreams(medias: [SRGMedia]) {
        
        var items: [CPListItem] = []

        for media in medias {
            print(media)
            let radioChannel = ApplicationConfiguration.shared.radioChannel(forUid: media.channel?.uid)
            let image = RadioChannelLogoImage(radioChannel)
            let listItem = CPListItem(text: media.title, detailText: media.urn, image: image)
            listItem.accessoryType = .disclosureIndicator
            items.append(listItem)
        }
        let section = CPListSection(items: items)
        radioLiveStreamsListTemplate.updateSections([section])
    }
    
    // MARK: - CPTemplateApplicationScene
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        
        self.interfaceController = interfaceController
        
        // Get radio live streams
        radioLiveStreamsViewModel.$medias
            .sink { [weak self] medias in
                guard let strongSelf = self else { return }
                strongSelf.updateRadioLiveStreams(medias: medias)
            }
            .store(in: &cancellables)
        
        // Create a list
//        let item = CPListItem(text: "title", detailText: "detail")
//        item.accessoryType = .disclosureIndicator
//        let section = CPListSection(items: [item])
//        let listTemplate = CPListTemplate(title: "Section", sections: [section])
//
        
        // Create a grid
        
        
        // Create a tab bar
        let tabBar = CPTabBarTemplate.init(templates: [radioLiveStreamsListTemplate, radioLiveStreamsGridTemplate])
        self.interfaceController?.setRootTemplate(tabBar, animated: true, completion: {_, _ in })
    }
    
    // CarPlay disconnected
    private func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
    
}
