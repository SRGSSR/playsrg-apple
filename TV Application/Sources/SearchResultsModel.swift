//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class SearchResultsModel: ObservableObject {
    enum State {
        case loading
        case failed(error: Error)
        case loaded(medias: [SRGMedia])
    }
    
    enum Medias {
        public typealias Page = SRGDataProvider.MediasMatchingQuery.Page
        public typealias Output = (medias: [SRGMedia], page: Page, nextPage: Page?, response: URLResponse)
    }
    
    @Published private(set) var state = State.loaded(medias: [])
    
    private var cancellables = Set<AnyCancellable>()
    private var medias: [SRGMedia] = []
    private var nextPage: Medias.Page? = nil
    
    @Published var query: String = "" {
        didSet {
            cancelRefresh()
            medias.removeAll()
            loadNextPage()
        }
    }
    
    func refresh() {
        guard medias.isEmpty else { return }
        loadNextPage()
    }
    
    func loadNextPage(from media: SRGMedia? = nil) {
        guard let publisher = publisher(from: media) else { return }
        publisher
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveRequest:  { _ in
                if self.medias.isEmpty {
                    self.state = .loading
                }
            })
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    self.state = .failed(error: error)
                }
            }, receiveValue: { result in
                self.medias.append(contentsOf: result.medias)
                self.state = .loaded(medias: self.medias)
                self.nextPage = result.nextPage
            })
            .store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
    
    private func publisher(from media: SRGMedia?) -> AnyPublisher<Medias.Output, Error>? {
        return searchPublisher(from: media)?
            .flatMap { searchResult in
                return SRGDataProvider.current!.medias(withUrns: searchResult.mediaUrns)
                    .map { mediaResult in
                        (mediaResult.medias, searchResult.page, searchResult.nextPage, searchResult.response)
                    }
            }
            .eraseToAnyPublisher()
    }
    
    private func searchPublisher(from media: SRGMedia?) -> AnyPublisher<SRGDataProvider.MediasMatchingQuery.Output, Error>? {
        if media != nil {
            guard let nextPage = nextPage, media == medias.last else { return nil }
            return SRGDataProvider.current!.medias(at: nextPage)
        }
        else {
            let applicationConfiguration = ApplicationConfiguration.shared
            return SRGDataProvider.current!.medias(for: applicationConfiguration.vendor, matchingQuery: query, with: nil, pageSize: applicationConfiguration.pageSize)
        }
    }
}
