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

    init(list: CarPlayList, template: CPListTemplate, interfaceController: CPInterfaceController) {
        self.list = list

        template.emptyViewSubtitleVariants = [NSLocalizedString("Loading…", comment: "Default text displayed when loading")]

        Publishers.Publish(onOutputFrom: reloadSignal()) {
            list.publisher(with: interfaceController)
                .map { State.loaded(sections: $0) }
                .catch { error in
                    Just(State.failed(error: error))
                }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak template] state in
            guard let template else { return }
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

    private func reloadSignal() -> AnyPublisher<Void, Never> {
        return Publishers.Merge(
            trigger.signal(activatedBy: TriggerId.reload),
            ApplicationSignal.wokenUp(.scene(filter: notificationFilter.self))
        )
        .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
        .eraseToAnyPublisher()
    }

    private func notificationFilter(notification: Notification) -> Bool {
        return notification.object is CPTemplateApplicationScene
    }
}

// MARK: Protocols

extension CarPlayTemplateListController: CarPlayTemplateController {
    func willAppear(animated _: Bool) {
        trigger.activate(for: TriggerId.reload)
    }

    func didAppear(animated _: Bool) {
        if let pageViewTitle = list.pageViewTitle, let pageViewType = list.pageViewType {
            SRGAnalyticsTracker.shared.uncheckedTrackPageView(withTitle: pageViewTitle, type: pageViewType, levels: list.pageViewLevels)
        }
    }

    func willDisappear(animated _: Bool) {}

    func didDisappear(animated _: Bool) {}
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
