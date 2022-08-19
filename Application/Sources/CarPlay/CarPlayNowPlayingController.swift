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
    private var popCancellable: AnyCancellable
    private var nowPlayingButtonsCancellable: AnyCancellable?
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // If the player is closed on the iOS device return to the first level. A better result would inspect the
        // template hierarchy to pop to the previous one but this might perform an IPC call. Popping to the root
        // should be sufficient.
        popCancellable = SRGLetterboxService.shared.publisher(for: \.controller)
            .filter { $0 == nil }
            .sink { [weak interfaceController] _ in
                interfaceController?.popToRootTemplate(animated: true) { _, _ in }
            }
    }
    
    private func playbackRateButton(for interfaceController: CPInterfaceController) -> CPNowPlayingButton {
        return CPNowPlayingImageButton(image: UIImage(systemName: "speedometer")!) { _ in
            interfaceController.pushTemplate(CPListTemplate.playbackRate, animated: true) { _, _ in }
        }
    }
    
    private func startOverButton() -> CPNowPlayingButton {
        return CPNowPlayingImageButton(image: UIImage(named: "start_over", in: nil, compatibleWith: UITraitCollection(userInterfaceIdiom: .carPlay))!) { _ in
            SRGLetterboxService.shared.controller?.startOver()
        }
    }
    
    private func skipToLiveButton() -> CPNowPlayingButton {
        return CPNowPlayingImageButton(image: UIImage(named: "skip_to_live", in: nil, compatibleWith: UITraitCollection(userInterfaceIdiom: .carPlay))!) { _ in
            SRGLetterboxService.shared.controller?.skipToLive()
        }
    }
    
    private func nowPlayingButtons(for controller: SRGLetterboxController?) -> [CPNowPlayingButton] {
        guard let controller = controller else { return [] }
        
        var nowPlayingButtons = [playbackRateButton(for: interfaceController!)]
        if controller.canStartOver() {
            nowPlayingButtons.insert(startOverButton(), at: 0)
        }
        if controller.canSkipToLive() {
            nowPlayingButtons.append(skipToLiveButton())
        }
        return nowPlayingButtons
    }
    
    private func nowPlayingButtonsPublisher() -> AnyPublisher<[CPNowPlayingButton], Never> {
        return SRGLetterboxService.shared.publisher(for: \.controller)
            .map { [weak self] controller -> AnyPublisher<[CPNowPlayingButton], Never> in
                if let controller = controller {
                    return Publishers.CombineLatest3(
                        controller.mediaPlayerController.publisher(for: \.timeRange),
                        NotificationCenter.default.publisher(for: .SRGLetterboxPlaybackStateDidChange, object: controller),
                        NotificationCenter.default.publisher(for: .SRGLetterboxMetadataDidChange, object: controller)
                    )
                    .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
                    .map { _ in
                        return self?.nowPlayingButtons(for: controller) ?? []
                    }
                    .prepend(self?.nowPlayingButtons(for: SRGLetterboxService.shared.controller) ?? [])
                    .eraseToAnyPublisher()
                }
                else {
                    return Just([])
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: Protocols

extension CarPlayNowPlayingController: CarPlayTemplateController {
    func willAppear(animated: Bool) {
        nowPlayingButtonsCancellable = nowPlayingButtonsPublisher()
            .sink { nowPlayingButtons in
                CPNowPlayingTemplate.shared.updateNowPlayingButtons(nowPlayingButtons)
            }
    }
    
    func didAppear(animated: Bool) {
        SRGAnalyticsTracker.shared.uncheckedTrackPageView(
            withTitle: AnalyticsPageTitle.player.rawValue,
            levels: [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue]
        )
    }
    
    func willDisappear(animated: Bool) {}
    
    func didDisappear(animated: Bool) {
        nowPlayingButtonsCancellable = nil
    }
}
