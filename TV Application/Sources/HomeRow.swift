//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class HomeRow: ObservableObject, Identifiable {
    enum Id : Equatable {
        case trending
        case latest
        case latestForTopic(_ topic: SRGTopic?)
        case latestForModule(_ module: SRGModule?)
    }
    
    let id: Id
    
    @Published var medias: [SRGMedia] = []
    
    var title: String {
        switch id {
            case .trending:
                return "Trending now"
            case .latest:
                return "Latest videos"
            case let .latestForModule(module):
                return module?.title ?? "Module"
            case let .latestForTopic(topic):
                return topic?.title ?? "Topic"
        }
    }
    
    init(id: Id) {
        self.id = id
    }
    
    func load() -> AnyCancellable? {
        let dataProvider = SRGDataProvider.current!
        let vendor = ApplicationConfiguration.vendor
        let pageSize = ApplicationConfiguration.pageSize
        
        switch id {
            case .trending:
                return dataProvider.tvTrendingMedias(for: vendor, pageSize: pageSize)
                    .map(\.medias)
                    .replaceError(with: [])
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.medias, on: self)
            case .latest:
                return dataProvider.tvLatestMedias(for: vendor, pageSize: pageSize)
                    .map(\.medias)
                    .replaceError(with: [])
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.medias, on: self)
            case let .latestForModule(module):
                guard let urn = module?.urn else { return nil }
                return dataProvider.latestMediasForModule(withUrn: urn, pageSize: pageSize)
                    .map(\.medias)
                    .replaceError(with: [])
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.medias, on: self)
            case let .latestForTopic(topic):
                guard let urn = topic?.urn else { return nil }
                return dataProvider.latestMediasForTopic(withUrn: urn, pageSize: pageSize)
                    .map(\.medias)
                    .replaceError(with: [])
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.medias, on: self)
        }
    }
}
