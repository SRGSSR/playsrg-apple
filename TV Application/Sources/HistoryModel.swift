//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGUserData

// TODO: Should implement a model protocol. Also should implement better refresh in general, probably
//       either deep (erase all cached content and restart from the first page) or smart incremental
//       (probably do not restart from the first page but updates the list with single changes received
//       from the history, so that they appear inlined into the results without having to reload everything).
class HistoryModel: ObservableObject {
    enum State {
        case loading
        case failed(error: Error)
        case loaded(medias: [SRGMedia])
    }
    
    @Published private(set) var state = State.loaded(medias: [])
    
    private var cancellables = Set<AnyCancellable>()
    private var medias: [SRGMedia] = []
    private var nextPage: SRGDataProvider.Medias.Page? = nil
    
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
    
    private func historyEntries() -> Future<[SRGHistoryEntry], Error> {
        return Future { promise in
            // TODO: Compile-checked keypath
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            SRGUserData.current!.history.historyEntries(matching: nil, sortedWith: [sortDescriptor]) { historyEntries, error in
                if let error = error {
                    promise(.failure(error))
                }
                else {
                    promise(.success(historyEntries ?? []))
                }
            }
        }
    }
    
    private func publisher(from media: SRGMedia?) -> AnyPublisher<SRGDataProvider.Medias.Output, Error>? {
        if media != nil {
            guard let nextPage = nextPage, media == medias.last else { return nil }
            return SRGDataProvider.current!.medias(at: nextPage)
        }
        else {
            return historyEntries()
                .map { historyEntries in
                    historyEntries.compactMap { $0.uid }
                }
                .flatMap { urns in
                    return SRGDataProvider.current!.medias(withUrns: urns, pageSize: ApplicationConfiguration.shared.pageSize)
                }
                .eraseToAnyPublisher()
        }
    }
}
