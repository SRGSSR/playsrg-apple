//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay
import SRGDataProviderCombine

// MARK: Controller

private final class CarPlayTemplateListController {
    private var cancellables = Set<AnyCancellable>()
    
    init(list: CarPlayList, template: CPListTemplate, interfaceController: CPInterfaceController) {
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.reachable()) {
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
                template.emptyViewSubtitleVariants = [NSLocalizedString("No results", comment: "No results label")]
                template.updateSections(sections)
            }
        }
        .store(in: &cancellables)
    }
}

// MARK: Types

extension CarPlayTemplateListController {
    enum State {
        case failed(error: Error)
        case loaded(sections: [CPListSection])
    }
}

// MARK: Template instantiation

private var controllerKey: Void?

extension CPListTemplate {
    convenience init(list: CarPlayList, interfaceController: CPInterfaceController) {
        self.init(title: list.title, sections: [])
        emptyViewSubtitleVariants = [NSLocalizedString("Loading…", comment: "Loading label")]
        
        let controller = CarPlayTemplateListController(list: list, template: self, interfaceController: interfaceController)
        objc_setAssociatedObject(self, &controllerKey, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
