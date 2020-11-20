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
        case loaded(alphabeticalShows: [(letter: Character, shows: [SRGShow])])
    }
    
    @Published private(set) var state = State.loaded(alphabeticalShows: [])
    
    private var cancellables = Set<AnyCancellable>()
    private var alphabeticalShows: [(letter: Character, shows: [SRGShow])] = []
    
    func refresh() {
        guard alphabeticalShows.isEmpty else { return }
        loadPage()
    }
    
    func loadPage() {
        guard let publisher = publisher() else { return }
        publisher
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveRequest:  { _ in
                if self.alphabeticalShows.isEmpty {
                    self.state = .loading
                }
            })
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    self.state = .failed(error: error)
                }
            }, receiveValue: { result in
                self.alphabeticalShows = Dictionary(grouping: result.shows) { (show) -> Character in
                    return show.title.uppercased().first! // TODO: group #, use upper case, remove accents / diacritics
                    }
                    .map { (key: Character, value: [SRGShow]) -> (letter: Character, shows: [SRGShow]) in
                        (letter: key, shows: value)
                    }
                    .sorted { (left, right) -> Bool in
                        left.letter < right.letter
                    }
                self.state = .loaded(alphabeticalShows: self.alphabeticalShows)
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
