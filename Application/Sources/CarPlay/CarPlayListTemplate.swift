//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay
import SRGDataProviderCombine

// MARK: Template

private var controllerKey: Void?

struct CarPlayListTemplate {
    static func template(list: CarPlayList, interfaceController: CPInterfaceController) -> CPListTemplate {
        let template = CPListTemplate(title: list.title, sections: [])
        template.emptyViewSubtitleVariants = [NSLocalizedString("Loading…", comment: "Loading label")]
        
        let controller = CarPlayTemplateListController(list: list, template: template, interfaceController: interfaceController)
        objc_setAssociatedObject(template, &controllerKey, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return template
    }
}

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
