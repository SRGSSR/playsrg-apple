//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class HomeRow: Identifiable, Equatable {
    enum Id: Equatable {
        case trending
        case latest
        case mostPopular
        case soonExpiring
        case latestForTopic(_ topic: SRGTopic?)
        case latestForModule(_ module: SRGModule?, type: SRGModuleType)
        case topics
    }
    
    static func makeRow(for id: Id) -> HomeRow {
        switch id {
            case .topics:
                return HomeTopicRow(id: id)
            default:
                return HomeMediaRow(id: id)
        }
    }
    
    final let id: Id
    
    var title: String? {
        return nil
    }
    
    func load() -> AnyCancellable? {
        return nil
    }
    
    init(id: Id) {
        self.id = id
    }
    
    static func == (lhs: HomeRow, rhs: HomeRow) -> Bool {
        return lhs.id == rhs.id
    }
}

final class HomeMediaRow: HomeRow, ObservableObject {
    @Published private(set) var medias: [SRGMedia] = []
    
    override var title: String? {
        switch id {
            case .trending:
                return "Trending now"
            case .latest:
                return "Latest videos"
            case .mostPopular:
                return "Popular"
            case .soonExpiring:
                return "Soon expiring"
            case let .latestForModule(module, type):
                if let module = module {
                    return module.title
                }
                else {
                    return Self.moduleTitle(for: type)
                }
            case let .latestForTopic(topic):
                return topic?.title ?? "Topic"
            default:
                return nil
        }
    }
    
    override func load() -> AnyCancellable? {
        return mediasPublisher()?
            .map(\.medias)
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: \.medias, on: self)
    }
    
    typealias Output = (medias: [SRGMedia], response: URLResponse)
    
    private func mediasPublisher() -> AnyPublisher<Output, Error>? {
        let dataProvider = SRGDataProvider.current!
        let vendor = ApplicationConfiguration.vendor
        let pageSize = ApplicationConfiguration.pageSize
        
        switch id {
            case .trending:
                return dataProvider.tvTrendingMedias(for: vendor, limit: pageSize, editorialLimit: ApplicationConfiguration.tvTrendingEditorialLimit,
                                                     episodesOnly: ApplicationConfiguration.tvTrendingEpisodesOnly)
            case .latest:
                return dataProvider.tvLatestMedias(for: vendor, pageSize: pageSize)
                    .map { ($0.medias, $0.response) }
                    .eraseToAnyPublisher()
            case .mostPopular:
                return dataProvider.tvMostPopularMedias(for: vendor, pageSize: pageSize)
                    .map { ($0.medias, $0.response) }
                    .eraseToAnyPublisher()
            case .soonExpiring:
                return dataProvider.tvSoonExpiringMedias(for: vendor, pageSize: pageSize)
                    .map { ($0.medias, $0.response) }
                    .eraseToAnyPublisher()
            case let .latestForModule(module, type: _):
                guard let urn = module?.urn else { return nil }
                return dataProvider.latestMediasForModule(withUrn: urn, pageSize: pageSize)
                    .map { ($0.medias, $0.response) }
                    .eraseToAnyPublisher()
            case let .latestForTopic(topic):
                guard let urn = topic?.urn else { return nil }
                return dataProvider.latestMediasForTopic(withUrn: urn, pageSize: pageSize)
                    .map { ($0.medias, $0.response) }
                    .eraseToAnyPublisher()
            default:
                return nil
        }
    }
    
    private static func moduleTitle(for type: SRGModuleType) -> String {
        return type == .event ? "Event" : "Module"
    }
}

final class HomeTopicRow: HomeRow, ObservableObject {
    @Published private(set) var topics: [SRGTopic] = []
    
    override var title: String? {
        switch id {
            case .topics:
                return nil;
            default:
                return nil;
        }
    }
    
    override func load() -> AnyCancellable? {
        switch id {
            case .topics:
                return SRGDataProvider.current!.tvTopics(for: ApplicationConfiguration.vendor)
                    .map(\.topics)
                    .replaceError(with: [])
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.topics, on: self)
            default:
                return nil;
        }
    }
}
