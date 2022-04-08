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
    
    private static func sections(interfaceController: CPInterfaceController) -> [CPListSection] {
        guard let controller = SRGLetterboxService.shared.controller else { return [] }
        let items = controller.supportedPlaybackRates
            .map(\.floatValue)
            .map { playbackRate -> CPListItem in
                let item: CPListItem
                if playbackRate == controller.playbackRate {
                    let detailText = (playbackRate != controller.effectivePlaybackRate) ? String(format: NSLocalizedString("The playback speed is restricted to %@×.", comment: "Information message about playback speed restrictions"), controller.effectivePlaybackRate.minimalRepresentation) : nil
                    item = CPListItem(text: "\(playbackRate.minimalRepresentation)×", detailText: detailText, image: nil, accessoryImage: UIImage(systemName: "checkmark"), accessoryType: .none)
                }
                else {
                    item = CPListItem(text: "\(playbackRate.minimalRepresentation)×", detailText: nil)
                }
                item.handler = { [weak controller] _, completion in
                    controller?.playbackRate = playbackRate
                    interfaceController.popTemplate(animated: true) { _, _ in
                        completion()
                    }
                }
                return item
        }
        return [CPListSection(items: items)]
    }
    
    init(template: CPListTemplate, interfaceController: CPInterfaceController) {
        template.emptyViewSubtitleVariants = [NSLocalizedString("No content", comment: "Default text displayed when no content is available")]
        
        if let controller = SRGLetterboxService.shared.controller {
            Self.playbackRateChangeSignal(for: controller)
                .sink { [weak template] _ in
                    template?.updateSections(Self.sections(interfaceController: interfaceController))
                }
                .store(in: &cancellables)
        }
    }
    
    private static func playbackRateChangeSignal(for controller: SRGLetterboxController) -> AnyPublisher<Void, Never> {
        return Publishers.Merge(
            controller.publisher(for: \.playbackRate),
            controller.publisher(for: \.effectivePlaybackRate)
        )
        .map { _ in }
        .eraseToAnyPublisher()
    }
}

// MARK: Protocols

extension CarPlayPlaybackSpeedController: CarPlayTemplateController {
    func willAppear(animated: Bool) {}
    
    func didAppear(animated: Bool) {}
    
    func willDisappear(animated: Bool) {}
    
    func didDisappear(animated: Bool) {}
}
