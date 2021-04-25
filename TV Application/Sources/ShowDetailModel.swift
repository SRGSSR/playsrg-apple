//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class ShowDetailModel: ObservableObject {
    let show: SRGShow
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(medias: [SRGMedia])
    }
    
    @Published private(set) var state = State.loading
    
    private var cancellables = Set<AnyCancellable>()
    private var medias: [SRGMedia] = []
    private var nextPage: SRGDataProvider.LatestMediasForShow.Page?
    
    init(show: SRGShow) {
        self.show = show
    }
    
    func refresh() {
        guard medias.isEmpty else { return }
        loadNextPage()
    }
    
    // Triggers a load only if the media is `nil` (first page) or the last one. We cannot observe scrolling yet,
    // so cell appearance must trigger a reload, and the last cell is used to load more content.
    // Also read https://www.donnywals.com/implementing-an-infinite-scrolling-list-with-swiftui-and-combine/
    func loadNextPage(from media: SRGMedia? = nil) {
        guard let publisher = publisher(from: media) else { return }
        publisher
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveRequest: { _ in
                if self.medias.isEmpty {
                    self.state = .loading
                }
            })
            .sink { completion in
                if case let .failure(error) = completion {
                    self.state = .failed(error: error)
                }
            } receiveValue: { result in
                self.medias.append(contentsOf: result.medias)
                self.state = .loaded(medias: self.medias)
                self.nextPage = result.nextPage
            }
            .store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
    
    private func publisher(from media: SRGMedia?) -> AnyPublisher<SRGDataProvider.LatestMediasForShow.Output, Error>? {
        if media != nil {
            guard let nextPage = nextPage, media == medias.last else { return nil }
            return SRGDataProvider.current!.latestMediasForShow(at: nextPage)
        }
        else {
            return SRGDataProvider.current!.latestMediasForShow(withUrn: show.urn, pageSize: ApplicationConfiguration.shared.pageSize)
        }
    }
}
