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
    private var nowPlayingPropertiesCancellable: AnyCancellable?

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
}

private extension CarPlayNowPlayingController {
    private struct NowPlayingProperties: Equatable {
        let nowPlayingButtons: [CPNowPlayingButton]
        let upNextButtonEnabled: Bool

        init(for controller: SRGLetterboxController?, interfaceController: CPInterfaceController) {
            nowPlayingButtons = Self.nowPlayingButtons(for: controller, interfaceController: interfaceController)
            upNextButtonEnabled = Self.upNextButtonEnabled(for: controller)
        }

        private static func playbackRateButton(for interfaceController: CPInterfaceController) -> CPNowPlayingButton {
            CPNowPlayingImageButton(image: UIImage(named: "playback_speed", in: nil, compatibleWith: UITraitCollection(userInterfaceIdiom: .carPlay))!) { _ in
                interfaceController.pushTemplate(CPListTemplate.playbackRate, animated: true) { _, _ in }
            }
        }

        private static func startOverButton() -> CPNowPlayingButton {
            CPNowPlayingImageButton(image: UIImage(named: "start_over", in: nil, compatibleWith: UITraitCollection(userInterfaceIdiom: .carPlay))!) { _ in
                SRGLetterboxService.shared.controller?.startOver()
            }
        }

        private static func skipToLiveButton() -> CPNowPlayingButton {
            CPNowPlayingImageButton(image: UIImage(named: "skip_to_live", in: nil, compatibleWith: UITraitCollection(userInterfaceIdiom: .carPlay))!) { _ in
                SRGLetterboxService.shared.controller?.skipToLive()
            }
        }

        private static func nowPlayingButtons(for controller: SRGLetterboxController?, interfaceController: CPInterfaceController) -> [CPNowPlayingButton] {
            guard let controller else { return [] }

            var nowPlayingButtons = [playbackRateButton(for: interfaceController)]
            if controller.canStartOver() {
                nowPlayingButtons.insert(startOverButton(), at: 0)
            }
            if controller.canSkipToLive() {
                nowPlayingButtons.append(skipToLiveButton())
            }
            return nowPlayingButtons
        }

        private static func upNextButtonEnabled(for controller: SRGLetterboxController?) -> Bool {
            if let mainChapter = controller?.mediaComposition?.mainChapter, mainChapter.contentType == .livestream,
               let segments = mainChapter.segments {
                !segments.isEmpty
            } else {
                false
            }
        }
    }

    private static func nowPlayingPropertiesPublisher(interfaceController: CPInterfaceController) -> AnyPublisher<NowPlayingProperties, Never> {
        SRGLetterboxService.shared.publisher(for: \.controller)
            .map { controller in
                if let controller {
                    Publishers.CombineLatest3(
                        controller.mediaPlayerController.publisher(for: \.timeRange),
                        NotificationCenter.default.weakPublisher(for: .SRGLetterboxPlaybackStateDidChange, object: controller),
                        NotificationCenter.default.weakPublisher(for: .SRGLetterboxMetadataDidChange, object: controller)
                    )
                    .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
                    .map { _ in
                        NowPlayingProperties(for: controller, interfaceController: interfaceController)
                    }
                    .prepend(NowPlayingProperties(for: controller, interfaceController: interfaceController))
                    .eraseToAnyPublisher()
                } else {
                    Just(NowPlayingProperties(for: controller, interfaceController: interfaceController))
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
    func willAppear(animated _: Bool) {
        CPNowPlayingTemplate.shared.add(self)
        nowPlayingPropertiesCancellable = Self.nowPlayingPropertiesPublisher(interfaceController: interfaceController!)
            .sink { nowPlayingProperties in
                let template = CPNowPlayingTemplate.shared
                template.updateNowPlayingButtons(nowPlayingProperties.nowPlayingButtons)
                template.isUpNextButtonEnabled = nowPlayingProperties.upNextButtonEnabled
            }
    }

    func didAppear(animated _: Bool) {
        SRGAnalyticsTracker.shared.uncheckedTrackPageView(
            withTitle: AnalyticsPageTitle.player.rawValue,
            type: AnalyticsPageType.detail.rawValue,
            levels: [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue]
        )
    }

    func willDisappear(animated _: Bool) {}

    func didDisappear(animated _: Bool) {
        nowPlayingPropertiesCancellable = nil
        CPNowPlayingTemplate.shared.remove(self)
    }
}

extension CarPlayNowPlayingController: CPNowPlayingTemplateObserver {
    func nowPlayingTemplateUpNextButtonTapped(_: CPNowPlayingTemplate) {
        if let channel = SRGLetterboxService.shared.controller?.channel,
           let media = SRGLetterboxService.shared.controller?.play_mainMedia,
           let interfaceController {
            let template = CPListTemplate.list(.livePrograms(channel: channel, media: media), interfaceController: interfaceController)
            interfaceController.pushTemplate(template, animated: true) { _, _ in }
        }
    }
}
