//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class ShowDetailModel: ObservableObject {
    enum State {
        case loading
        case failed(error: Error)
        case loaded(medias: [SRGMedia])
    }
    
    @Published var show: SRGShow? = nil {
        willSet {
            if show != newValue {
                medias.removeAll()
            }
        }
        didSet {
            guard medias.isEmpty else { return }
            refresh()
        }
    }
    
    @Published private(set) var state = State.loading
    
    private var cancellables = Set<AnyCancellable>()
    private var medias: [SRGMedia] = []
    
    static let triggerIndex = 1
    
    let trigger = Trigger()
    
    func refresh() {
        guard let show = show else { return }
        SRGDataProvider.current!.latestMediasForShow(withUrn: show.urn, pageSize: ApplicationConfiguration.shared.pageSize, paginatedBy: trigger.triggerable(activatedBy: Self.triggerIndex))
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveRequest: { [weak self] _ in
                guard let self = self else { return }
                if self.medias.isEmpty {
                    self.state = .loading
                }
            })
            .sink { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    self.state = .failed(error: error)
                }
            } receiveValue: { [weak self] medias in
                guard let self = self else { return }
                self.medias.append(contentsOf: medias)
                self.state = .loaded(medias: self.medias)
            }
            .store(in: &cancellables)
    }
    
    func loadNextPage(from media: SRGMedia) {
        if media == medias.last {
            trigger.activate(for: Self.triggerIndex)
        }
    }
}
