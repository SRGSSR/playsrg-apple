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
        case loaded(medias: [SRGMedia])
    }
    
    @Published private(set) var state = State.loaded(medias: [])
    
    private var cancellables = Set<AnyCancellable>()
    private var medias: [SRGMedia] = []
    private var nextPage: SRGDataProvider.LatestMediasForTopic.Page? = nil
    
    init(topic: SRGTopic) {
        self.topic = topic
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
    
    private func publisher(from media: SRGMedia?) -> AnyPublisher<SRGDataProvider.LatestMediasForTopic.Output, Error>? {
        if media != nil {
            guard let nextPage = nextPage, media == medias.last else { return nil }
            return SRGDataProvider.current!.latestMediasForTopic(at: nextPage)
        }
        else {
            return SRGDataProvider.current!.latestMediasForTopic(withUrn: topic.urn, pageSize: ApplicationConfiguration.shared.pageSize)
        }
    }
}
