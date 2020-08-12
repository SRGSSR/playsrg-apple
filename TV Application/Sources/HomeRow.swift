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
        case topics
        case latestForTopic(_ topic: SRGTopic)
    }
    
    let id: Id
    
    @Published var medias: [SRGMedia] = []
    
    var title: String {
        switch id {
            case .trending:
                return "Trending now"
            case .latest:
                return "Latest videos"
            case .topics:
                return "Topics"
            case let .latestForTopic(topic):
                return topic.title
        }
    }
    
    init(id: Id) {
        self.id = id
    }
    
    func load() -> AnyCancellable? {
        let dataProvider = SRGDataProvider.current!
        switch id {
            case .trending:
                return dataProvider.tvTrendingMedias(for: .RTS)
                    .map(\.medias)
                    .replaceError(with: [])
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.medias, on: self)
            case .latest:
                return dataProvider.tvLatestMedias(for: .RTS)
                    .map(\.medias)
                    .replaceError(with: [])
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.medias, on: self)
            case .topics:
                return nil
            case let .latestForTopic(topic):
                return dataProvider.latestMediasForTopic(withUrn: topic.urn)
                    .map(\.medias)
                    .replaceError(with: [])
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.medias, on: self)
        }
    }
}
