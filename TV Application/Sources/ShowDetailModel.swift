//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class ShowDetailModel: ObservableObject {
    let show: SRGShow
    
    typealias Row = CollectionRow<Section, SRGMedia>
    
    @Published private(set) var rows: [Row] = []
    @Published private(set) var error: Error? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private var nextPage: SRGDataProvider.LatestMediasForShows.Page? = nil
    
    init(show: SRGShow) {
        self.show = show
    }
    
    func refresh() {
        loadNextPage()
    }
    
    // Triggers a load only if the media is `nil` (first page) or the last one. We cannot observe scrolling yet,
    // so cell appearance must trigger a reload, and the last cell is used to load more content.
    // Also read https://www.donnywals.com/implementing-an-infinite-scrolling-list-with-swiftui-and-combine/
    func loadNextPage(from media: SRGMedia? = nil) {
        guard let publisher = publisher(from: media) else { return }
        publisher.receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    self.error = error
                }
                else {
                    self.error = nil
                }
            }, receiveValue: { result in
                var medias = self.rows.first?.items ?? []
                medias.append(contentsOf: result.medias)
                
                self.rows = [Row(section: .main, items: medias)]
                self.nextPage = result.nextPage
            })
            .store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
    
    private func publisher(from media: SRGMedia?) -> AnyPublisher<SRGDataProvider.LatestMediasForShows.Output, Error>? {
        // TODO: Probably use episode composition request, which returns more episodes in the past
        if let media = media {
            guard let nextPage = nextPage, media == rows.first?.items.last else { return nil }
            return SRGDataProvider.current!.latestMediasForShows(at: nextPage)
        }
        else {
            return SRGDataProvider.current!.latestMediasForShows(withUrns: [show.urn], pageSize: ApplicationConfiguration.shared.pageSize)
        }
    }
}

extension ShowDetailModel {
    enum Section: Hashable {
        case main
    }
}
