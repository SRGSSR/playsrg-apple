//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class ShowsModel: ObservableObject {
    enum State {
        case loading
        case failed(error: Error)
        case loaded(shows: [SRGShow])
    }
    
    @Published private(set) var state = State.loaded(shows: [])
    
    private var cancellables = Set<AnyCancellable>()
    private var shows: [SRGShow] = []
    
    func refresh() {
        guard shows.isEmpty else { return }
        loadPage()
    }
    
    func loadPage() {
        guard let publisher = publisher() else { return }
        publisher
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveRequest:  { _ in
                if self.shows.isEmpty {
                    self.state = .loading
                }
            })
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    self.state = .failed(error: error)
                }
            }, receiveValue: { result in
                self.shows.append(contentsOf: result.shows)
                self.state = .loaded(shows: self.shows)
            })
            .store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
    
    private func publisher() -> AnyPublisher<SRGDataProvider.TVShows.Output, Error>? {
        return SRGDataProvider.current!.tvShows(for: ApplicationConfiguration.shared.vendor, pageSize: SRGDataProviderUnlimitedPageSize)
    }
}
