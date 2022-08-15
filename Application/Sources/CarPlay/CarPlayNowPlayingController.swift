//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay
import Combine
import SRGLetterbox

// MARK: Controller

final class CarPlayNowPlayingController {
    private weak var interfaceController: CPInterfaceController?
    private var cancellables = Set<AnyCancellable>()
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // If the player is closed on the iOS device return to the first level. A better result would inspect the
        // template hierarchy to pop to the previous one but this might perform an IPC call. Popping to the root
        // should be sufficient.
        SRGLetterboxService.shared.publisher(for: \.controller)
            .filter { $0 == nil }
            .sink { [weak interfaceController] _ in
                interfaceController?.popToRootTemplate(animated: true) { _, _ in }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .SRGLetterboxPlaybackStateDidChange, object: nil)
            .sink { [self] _ in
                self.updateNowPlayingButtons()
            }
            .store(in: &cancellables)
    }
    
    private func playbackRateButton(for interfaceController: CPInterfaceController) -> CPNowPlayingButton {
        return CPNowPlayingImageButton(image: UIImage(systemName: "speedometer")!) { _ in
            interfaceController.pushTemplate(CPListTemplate.playbackRate, animated: true) { _, _ in }
        }
    }
    
    private func startOverButton() -> CPNowPlayingButton {
        return CPNowPlayingImageButton(image: UIImage(named: "start_over")!) { _ in
            SRGLetterboxService.shared.controller?.startOver()
        }
    }
    
    private func skipToLiveButton() -> CPNowPlayingButton {
        return CPNowPlayingImageButton(image: UIImage(named: "skip_to_live")!) { _ in
            SRGLetterboxService.shared.controller?.skipToLive()
        }
    }
    
    private func updateNowPlayingButtons() {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        
        if let controller = SRGLetterboxService.shared.controller {
            var nowPlayingButtons = [playbackRateButton(for: interfaceController!)]
            if controller.canStartOver() {
                nowPlayingButtons.insert(startOverButton(), at: 0)
            }
            if controller.canSkipToLive() {
                nowPlayingButtons.append(skipToLiveButton())
            }
            nowPlayingTemplate.updateNowPlayingButtons(nowPlayingButtons)
        }
        else {
            nowPlayingTemplate.updateNowPlayingButtons([])
        }
    }
}

// MARK: Protocols

extension CarPlayNowPlayingController: CarPlayTemplateController {
    func willAppear(animated: Bool) {
        updateNowPlayingButtons()
    }
    
    func didAppear(animated: Bool) {
        SRGAnalyticsTracker.shared.uncheckedTrackPageView(
            withTitle: AnalyticsPageTitle.player.rawValue,
            levels: [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue]
        )
    }
    
    func willDisappear(animated: Bool) {}
    
    func didDisappear(animated: Bool) {}
}
