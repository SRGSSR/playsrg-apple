//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay
import SRGAnalytics
import SRGDataProviderCombine

// MARK: Controller

final class CarPlayTemplateListController {
    private let list: CarPlayList
    private var cancellables = Set<AnyCancellable>()
    
    private let trigger = Trigger()
    private var displayedOnce = false
    
    init(list: CarPlayList, template: CPListTemplate, interfaceController: CPInterfaceController) {
        self.list = list
        
        template.emptyViewSubtitleVariants = [NSLocalizedString("Loading…", comment: "Default text displayed when loading")]
        
        Publishers.PublishAndRepeat(onOutputFrom: reloadPublisher()) {
            list.publisher(with: interfaceController)
                .map { State.loaded(sections: $0) }
                .catch { error in
                    return Just(State.failed(error: error))
                }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak template] state in
            guard let template = template else { return }
            switch state {
            case let .failed(error: error):
                template.emptyViewSubtitleVariants = [error.localizedDescription]
                template.updateSections([])
            case let .loaded(sections: sections):
                template.emptyViewSubtitleVariants = [NSLocalizedString("No content", comment: "Default text displayed when no content is available")]
                template.updateSections(sections)
            }
        }
        .store(in: &cancellables)
    }
    
    private func reloadPublisher() -> AnyPublisher<Void, Never> {
        return Publishers.Merge(
            ApplicationSignal.reachable(),
            trigger.signal(activatedBy: TriggerId.reload)
        ).eraseToAnyPublisher()
    }
}

// MARK: Protocols

extension CarPlayTemplateListController: CarPlayTemplateController {
    func willAppear(animated: Bool) {
        if displayedOnce {
            trigger.activate(for: TriggerId.reload)
        }
        else {
            displayedOnce = true
        }
    }
    
    func didAppear(animated: Bool) {
        if let pageViewTitle = list.pageViewTitle {
            SRGAnalyticsTracker.shared.uncheckedTrackPageView(withTitle: pageViewTitle, levels: list.pageViewLevels)
        }
    }
    
    func willDisappear(animated: Bool) {}
    
    func didDisappear(animated: Bool) {}
}

// MARK: Types

extension CarPlayTemplateListController {
    enum State {
        case failed(error: Error)
        case loaded(sections: [CPListSection])
    }
    
    enum TriggerId {
        case reload
    }
}
