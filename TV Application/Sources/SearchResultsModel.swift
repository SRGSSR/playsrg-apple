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
        case mostSearched(shows: [SRGShow])
        case loaded(medias: [SRGMedia], suggestions: [SRGSearchSuggestion])
    }
    
    enum Medias {
        public typealias Page = SRGDataProvider.MediasMatchingQuery.Page
        public typealias Output = (medias: [SRGMedia], suggestions: [SRGSearchSuggestion], page: Page, nextPage: Page?, response: URLResponse)
    }
    
    private var querySubject = CurrentValueSubject<String, Never>("")
    
    var query: String {
        get {
            querySubject.value
        }
        set {
            querySubject.value = newValue
        }
    }
    
    @Published private(set) var state = State.loaded(medias: [], suggestions: [])
    
    weak var searchController: UISearchController? = nil
    weak var viewController: UIViewController? = nil
    
    private var globalCancellables = Set<AnyCancellable>()
    private var refreshCancellables = Set<AnyCancellable>()
    
    private var medias: [SRGMedia] = []
    private var nextPage: Medias.Page? = nil
    
    init() {
        querySubject
            .removeDuplicates()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { _ in
                self.medias.removeAll()
                self.nextPage = nil
                
                self.cancelRefresh()
                self.loadNextPage()
            }
            .store(in: &globalCancellables)
    }
    
    func refresh() {
        guard medias.isEmpty else { return }
        loadNextPage()
    }
    
    func loadNextPage(from media: SRGMedia? = nil) {
        guard !query.isEmpty else {
            if ApplicationConfiguration.shared.isShowsSearchHidden {
                self.state = .loaded(medias: [], suggestions: [])
            }
            else {
                SRGDataProvider.current!.mostSearchedShows(for: ApplicationConfiguration.shared.vendor, mediaType: .video)
                    .receive(on: DispatchQueue.main)
                    .handleEvents(receiveRequest: { _ in
                        self.state = .loading
                    })
                    .sink { completion in
                        if case let .failure(error) = completion {
                            self.state = .failed(error: error)
                        }
                    } receiveValue: { result in
                        self.state = .mostSearched(shows: result.shows)
                    }
                    .store(in: &refreshCancellables)
            }
            return
        }
        
        guard let publisher = mediaPublisher(from: media) else { return }
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
                self.state = .loaded(medias: self.medias, suggestions: result.suggestions)
                self.nextPage = result.nextPage
            }
            .store(in: &refreshCancellables)
    }
    
    func cancelRefresh() {
        refreshCancellables = []
    }
    
    private var searchSettings: SRGMediaSearchSettings? {
        guard !ApplicationConfiguration.shared.areSearchSettingsHidden else { return nil }
        
        let settings = SRGMediaSearchSettings()
        settings.mediaType = .video
        settings.suggestionsEnabled = true
        return settings
    }
    
    private func mediaPublisher(from media: SRGMedia?) -> AnyPublisher<Medias.Output, Error>? {
        return mediaSearchPublisher(from: media)?
            .flatMap { searchResult in
                return SRGDataProvider.current!.medias(withUrns: searchResult.mediaUrns, pageSize: ApplicationConfiguration.shared.pageSize)
                    .map { mediaResult in
                        (mediaResult.medias, searchResult.suggestions ?? [], searchResult.page, searchResult.nextPage, searchResult.response)
                    }
            }
            .eraseToAnyPublisher()
    }
    
    private func mediaSearchPublisher(from media: SRGMedia?) -> AnyPublisher<SRGDataProvider.MediasMatchingQuery.Output, Error>? {
        if media != nil {
            guard let nextPage = nextPage, media == medias.last else { return nil }
            return SRGDataProvider.current!.medias(at: nextPage)
        }
        else {
            let applicationConfiguration = ApplicationConfiguration.shared
            return SRGDataProvider.current!.medias(for: applicationConfiguration.vendor, matchingQuery: query, with: searchSettings, pageSize: applicationConfiguration.pageSize)
        }
    }
}
