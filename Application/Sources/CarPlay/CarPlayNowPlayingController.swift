//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay
import Combine
import SRGLetterbox

// MARK: Controller

final class CarPlayNowPlayingController: NSObject {
    private weak var interfaceController: CPInterfaceController?
    private var popToRootCancellable: AnyCancellable
    private var nowPlayingButtonsCancellable: AnyCancellable?
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // If the player is closed on the iOS device return to the first level. A better result would inspect the
        // template hierarchy to pop to the previous one but this might perform an IPC call. Popping to the root
        // should be sufficient.
        popToRootCancellable = SRGLetterboxService.shared.publisher(for: \.controller)
            .filter { $0 == nil }
            .sink { [weak interfaceController] _ in
                interfaceController?.popToRootTemplate(animated: true) { _, _ in }
            }
        
        CPNowPlayingTemplate.shared.upNextTitle = NSLocalizedString("Previous shows", comment: "Button title on CarPlay player for livestream previous programs")
    }
    
    private static func playbackRateButton(for interfaceController: CPInterfaceController) -> CPNowPlayingButton {
        return CPNowPlayingImageButton(image: UIImage(systemName: "speedometer")!) { _ in
            interfaceController.pushTemplate(CPListTemplate.playbackRate, animated: true) { _, _ in }
        }
    }
    
    private static func startOverButton() -> CPNowPlayingButton {
        return CPNowPlayingImageButton(image: UIImage(named: "start_over", in: nil, compatibleWith: UITraitCollection(userInterfaceIdiom: .carPlay))!) { _ in
            SRGLetterboxService.shared.controller?.startOver()
        }
    }
    
    private static func skipToLiveButton() -> CPNowPlayingButton {
        return CPNowPlayingImageButton(image: UIImage(named: "skip_to_live", in: nil, compatibleWith: UITraitCollection(userInterfaceIdiom: .carPlay))!) { _ in
            SRGLetterboxService.shared.controller?.skipToLive()
        }
    }
    
    private static func nowPlayingButtons(for controller: SRGLetterboxController?, interfaceController: CPInterfaceController) -> [CPNowPlayingButton] {
        guard let controller = controller else { return [] }
        
        var nowPlayingButtons = [playbackRateButton(for: interfaceController)]
        if controller.canStartOver() {
            nowPlayingButtons.insert(startOverButton(), at: 0)
        }
        if controller.canSkipToLive() {
            nowPlayingButtons.append(skipToLiveButton())
        }
        return nowPlayingButtons
    }
    
    private static var isUpNextButtonEnabled: Bool {
        if let mainChapter = SRGLetterboxService.shared.controller?.mediaComposition?.mainChapter,
           mainChapter.contentType == .livestream,
           let segments = mainChapter.segments {
            return !segments.isEmpty
        }
        else {
            return false
        }
    }
    
    private static func nowPlayingButtonsPublisher(interfaceController: CPInterfaceController) -> AnyPublisher<[CPNowPlayingButton], Never> {
        return SRGLetterboxService.shared.publisher(for: \.controller)
            .map { controller -> AnyPublisher<[CPNowPlayingButton], Never> in
                if let controller = controller {
                    return Publishers.CombineLatest3(
                        controller.mediaPlayerController.publisher(for: \.timeRange),
                        NotificationCenter.default.weakPublisher(for: .SRGLetterboxPlaybackStateDidChange, object: controller),
                        NotificationCenter.default.weakPublisher(for: .SRGLetterboxMetadataDidChange, object: controller)
                    )
                    .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
                    .map { _ in
                        return Self.nowPlayingButtons(for: controller, interfaceController: interfaceController)
                    }
                    .prepend(Self.nowPlayingButtons(for: controller, interfaceController: interfaceController))
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
        CPNowPlayingTemplate.shared.add(self)
        nowPlayingButtonsCancellable = Self.nowPlayingButtonsPublisher(interfaceController: interfaceController!)
            .sink { nowPlayingButtons in
                let template = CPNowPlayingTemplate.shared
                template.updateNowPlayingButtons(nowPlayingButtons)
                template.isUpNextButtonEnabled = Self.isUpNextButtonEnabled
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
        CPNowPlayingTemplate.shared.remove(self)
    }
}

extension CarPlayNowPlayingController: CPNowPlayingTemplateObserver {
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        if Self.isUpNextButtonEnabled,
           let channel = SRGLetterboxService.shared.controller?.channel,
           let media = SRGLetterboxService.shared.controller?.play_mainMedia,
           let interfaceController = interfaceController {
            let template = CPListTemplate.list(.livePrograms(channel: channel, media: media), interfaceController: interfaceController)
            interfaceController.pushTemplate(template, animated: true) { _, _ in }
        }
    }
}
