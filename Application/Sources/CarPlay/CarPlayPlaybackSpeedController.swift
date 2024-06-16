//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay
import Combine
import SRGLetterbox

// MARK: Controller

final class CarPlayPlaybackSpeedController {
    private var cancellables = Set<AnyCancellable>()

    private static func sections(template: CPListTemplate?) -> [CPListSection] {
        guard let controller = SRGLetterboxService.shared.controller else { return [] }
        let items = controller.supportedPlaybackRates
            .map(\.floatValue)
            .map { playbackRate in
                let item = CPListItem(
                    text: Self.text(forPlaybackRate: playbackRate, controller: controller),
                    detailText: nil,
                    image: nil,
                    accessoryImage: Self.accessoryImage(forPlaybackRate: playbackRate, controller: controller),
                    accessoryType: .none
                )
                item.handler = { [weak controller, weak template] _, completion in
                    controller?.playbackRate = playbackRate
                    template?.updateSections(sections(template: template))
                    completion()
                }
                return item
            }
        return [CPListSection(items: items)]
    }

    init(template: CPListTemplate) {
        template.emptyViewSubtitleVariants = [NSLocalizedString("No content", comment: "Default text displayed when no content is available")]

        if let controller = SRGLetterboxService.shared.controller {
            Self.playbackRateChangeSignal(for: controller)
                .sink { [weak template] _ in
                    template?.updateSections(Self.sections(template: template))
                }
                .store(in: &cancellables)
        }
    }

    private static func text(forPlaybackRate playbackRate: Float, controller: SRGLetterboxController) -> String {
        let effectivePlaybackRate = controller.effectivePlaybackRate
        if playbackRate == controller.playbackRate, playbackRate != effectivePlaybackRate {
            return String(format: NSLocalizedString("%1$@× (Currently: %2$@×)", comment: "Speed factor with current value if different from desired one"), playbackRate.minimalRepresentation, effectivePlaybackRate.minimalRepresentation)
        } else {
            return String(format: NSLocalizedString("%@×", comment: "Speed factor"), playbackRate.minimalRepresentation)
        }
    }

    private static func accessoryImage(forPlaybackRate playbackRate: Float, controller: SRGLetterboxController) -> UIImage? {
        playbackRate == controller.playbackRate ? UIImage(systemName: "checkmark") : nil
    }

    private static func playbackRateChangeSignal(for controller: SRGLetterboxController) -> AnyPublisher<Void, Never> {
        Publishers.Merge(
            controller.publisher(for: \.playbackRate),
            controller.publisher(for: \.effectivePlaybackRate)
        )
        .map { _ in }
        .eraseToAnyPublisher()
    }
}

// MARK: Protocols

extension CarPlayPlaybackSpeedController: CarPlayTemplateController {
    func willAppear(animated _: Bool) {}

    func didAppear(animated _: Bool) {}

    func willDisappear(animated _: Bool) {}

    func didDisappear(animated _: Bool) {}
}
