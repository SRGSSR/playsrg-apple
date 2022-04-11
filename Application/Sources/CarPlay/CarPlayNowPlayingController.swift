//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay
import Combine
import SRGLetterbox

// MARK: Controller

final class CarPlayNowPlayingController: CarPlayTemplateController {
    private weak var interfaceController: CPInterfaceController?
    private var cancellables = Set<AnyCancellable>()
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // If the player is closed on the iOS device return to the first level. A better result would inspect the
        // template hierarchy to pop to the previous one but this might perform an IPC call. Popping to the root
        // should be sufficient.
        SRGLetterboxService.shared.publisher(for: \.controller)
            .filter { $0 == nil }
            .sink { [weak interfaceController] controller in
                interfaceController?.popToRootTemplate(animated: true) { _, _ in }
            }
            .store(in: &cancellables)
    }
    
    func willAppear(animated: Bool) {}
    
    func didAppear(animated: Bool) {
        SRGAnalyticsTracker.shared.uncheckedTrackPageView(
            withTitle: AnalyticsPageTitle.player.rawValue,
            levels: [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue]
        )
    }
    
    func willDisappear(animated: Bool) {}
    
    func didDisappear(animated: Bool) {}
}
