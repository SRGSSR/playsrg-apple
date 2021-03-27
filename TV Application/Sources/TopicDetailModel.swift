//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class TopicDetailModel: ObservableObject {
    let topic: SRGTopic
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(mostPopularMedias: [SRGMedia], latestMedias: [SRGMedia])
    }
    
    @Published private(set) var state = State.loading
    
    private var cancellables = Set<AnyCancellable>()
    
    private var mostPopularMedias: [SRGMedia] = []
    
    private var latestMedias: [SRGMedia] = []
    private var nextPage: SRGDataProvider.LatestMediasForTopic.Page? = nil
    
    init(topic: SRGTopic) {
        self.topic = topic
    }
    
    func refresh() {
        // Pagination is on latest medias, so if some are already loaded do not perform a refresh
        guard latestMedias.isEmpty else { return }
        loadNextPage()
    }
    
    func loadNextPage(from media: SRGMedia? = nil) {
        guard let latestPublisher = latestPublisher(from: media) else { return }
        
        let mostPopularPublisher = SRGDataProvider.current!.mostPopularMediasForTopic(withUrn: topic.urn, pageSize: ApplicationConfiguration.shared.pageSize)
        Publishers.CombineLatest(mostPopularPublisher, latestPublisher)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveRequest:  { _ in
                if self.mostPopularMedias.isEmpty && self.latestMedias.isEmpty {
                    self.state = .loading
                }
            })
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    self.state = .failed(error: error)
                }
            }, receiveValue: { combined in
                self.mostPopularMedias = combined.0.medias
                self.latestMedias.append(contentsOf: combined.1.medias)
                self.state = .loaded(mostPopularMedias: self.mostPopularMedias, latestMedias: self.latestMedias)
                self.nextPage = combined.1.nextPage
            })
            .store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
    
    private func latestPublisher(from media: SRGMedia?) -> AnyPublisher<SRGDataProvider.LatestMediasForTopic.Output, Error>? {
        if media != nil {
            guard let nextPage = nextPage, media == latestMedias.last else { return nil }
            return SRGDataProvider.current!.latestMediasForTopic(at: nextPage)
        }
        else {
            return SRGDataProvider.current!.latestMediasForTopic(withUrn: topic.urn, pageSize: ApplicationConfiguration.shared.pageSize)
        }
    }
}
