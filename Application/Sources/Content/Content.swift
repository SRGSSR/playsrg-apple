//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

private let defaultNumberOfPlaceholders = 10
private let defaultNumberOfLivestreamPlaceholders = 4

// MARK: Types

enum Content {
    enum Section: Hashable {
        case content(SRGContentSection)
        case configured(ConfiguredSection)
        
        var properties: SectionProperties {
            switch self {
            case let .content(section):
                return ContentSectionProperties(contentSection: section)
            case let .configured(section):
                return ConfiguredSectionProperties(configuredSection: section)
            }
        }
    }
    
    enum Item: Hashable {
        case mediaPlaceholder(index: Int)
        case media(_ media: SRGMedia)
        
        case showPlaceholder(index: Int)
        case show(_ show: SRGShow)
        case showHeader(_ show: SRGShow)
        
        case topicPlaceholder(index: Int)
        case topic(_ topic: SRGTopic)
        
        @available(tvOS, unavailable)
        case showAccess(radioChannel: RadioChannel?)
    }
}

// MARK: Content section properties

private extension Content {
    struct ContentSectionProperties: SectionProperties {
        let contentSection: SRGContentSection
        
        private var presentation: SRGContentPresentation {
            return contentSection.presentation
        }
        
        var title: String? {
            if let title = presentation.title {
                return title
            }
            else {
                switch presentation.type {
                case .favoriteShows:
                    return NSLocalizedString("Favorites", comment: "Title label used to present the TV or radio favorite shows")
                case .personalizedProgram:
                    return NSLocalizedString("Latest episodes from your favorites", comment: "Title label used to present the latest episodes from TV favorite shows")
                case .livestreams:
                    return NSLocalizedString("TV channels", comment: "Title label to present main TV livestreams")
                case .resumePlayback:
                    return NSLocalizedString("Resume playback", comment: "Title label used to present medias whose playback can be resumed")
                case .watchLater:
                    return NSLocalizedString("Later", comment: "Title Label used to present the video later list")
                case .showAccess:
                    return NSLocalizedString("Shows", comment: "Title label used to present the TV shows AZ and TV shows by date access buttons")
                default:
                    return nil
                }
            }
        }
        
        var summary: String? {
            return presentation.summary
        }
        
        var label: String? {
            return presentation.label
        }
        
        var placeholderItems: [Content.Item] {
            switch presentation.type {
            case .mediaHighlight:
                return [.mediaPlaceholder(index: 0)]
            case .showHighlight:
                return [.showPlaceholder(index: 0)]
            case .topicSelector:
                return (0..<defaultNumberOfPlaceholders).map { .topicPlaceholder(index: $0) }
            case .swimlane, .hero, .grid:
                return (0..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .livestreams:
                return (0..<defaultNumberOfLivestreamPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .none, .favoriteShows, .resumePlayback, .watchLater, .personalizedProgram, .showAccess:
                return []
            }
        }
        
        func publisher(triggerId: Trigger.Id, filter: SectionFiltering?) -> AnyPublisher<[Content.Item], Error>? {
            let dataProvider = SRGDataProvider.current!
            let configuration = ApplicationConfiguration.shared
            
            let vendor = configuration.vendor
            let pageSize = configuration.pageSize
            
            switch contentSection.type {
            case .medias:
                return dataProvider.medias(for: vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, triggerId: triggerId)
                    .map { self.filterItems($0).map { .media($0) } }
                    .eraseToAnyPublisher()
            case .showAndMedias:
                return dataProvider.showAndMedias(for: vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, triggerId: triggerId)
                    .map {
                        var items = [Content.Item]()
                        if let show = $0.show {
                            items.append(.showHeader(show))
                        }
                        items.append(contentsOf: $0.medias.map { .media($0) })
                        return items
                    }
                    .eraseToAnyPublisher()
            case .shows:
                return dataProvider.shows(for: vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, triggerId: triggerId)
                    .map { self.filterItems($0).map { .show($0) } }
                    .eraseToAnyPublisher()
            case .predefined:
                switch presentation.type {
                case .favoriteShows:
                    return dataProvider.favoritesPublisher(filter: filter)
                        .map { $0.map { .show($0) } }
                        .eraseToAnyPublisher()
                case .personalizedProgram:
                    return dataProvider.favoritesPublisher(filter: filter)
                        .map { dataProvider.latestMediasForShowsPublisher(withUrns: $0.map(\.urn)) }
                        .switchToLatest()
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case .livestreams:
                    return dataProvider.tvLivestreams(for: vendor)
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case .topicSelector:
                    return dataProvider.tvTopics(for: vendor)
                        .map { $0.map { .topic($0) } }
                        .eraseToAnyPublisher()
                case .resumePlayback:
                    return dataProvider.historyPublisher()
                        .map { medias in
                            let filteredMedias = filter?.compatibleMedias(medias) ?? medias
                            return filteredMedias.prefix(Int(pageSize)).map { .media($0) }
                        }
                        .eraseToAnyPublisher()
                case .watchLater:
                    return dataProvider.laterPublisher()
                        .map { medias in
                            let filteredMedias = filter?.compatibleMedias(medias) ?? medias
                            return filteredMedias.prefix(Int(pageSize)).map { .media($0) } }
                        .eraseToAnyPublisher()
                case .showAccess:
                    #if os(iOS)
                    return Just([.showAccess(radioChannel: nil)])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                    #else
                    return nil
                    #endif
                case .none, .swimlane, .hero, .grid, .mediaHighlight, .showHighlight:
                    return nil
                }
            case .none:
                return nil
            }
        }
        
        private func filterItems<T>(_ items: [T]) -> [T] {
            guard presentation.type == .mediaHighlight || presentation.type == .showHighlight else { return items }
            
            if presentation.isRandomized, let item = items.randomElement() {
                return [item]
            }
            else if !presentation.isRandomized, let item = items.first {
                return [item]
            }
            else {
                return []
            }
        }
    }
}

// MARK: Configured section properties

private extension Content {
    struct ConfiguredSectionProperties: SectionProperties {
        let configuredSection: ConfiguredSection
        
        var title: String? {
            switch configuredSection.type {
            case .radioLatestEpisodes:
                return NSLocalizedString("The latest episodes", comment: "Title label used to present the radio latest audio episodes")
            case .radioMostPopular:
                return NSLocalizedString("Most listened to", comment: "Title label used to present the radio most popular audio medias")
            case .radioLatest:
                return NSLocalizedString("The latest audios", comment: "Title label used to present the radio latest audios")
            case .radioLatestVideos:
                return NSLocalizedString("Latest videos", comment: "Title label used to present the radio latest videos")
            case .radioAllShows:
                return NSLocalizedString("Shows", comment: "Title label used to present radio associated shows")
            case .radioFavoriteShows:
                return NSLocalizedString("Favorites", comment: "Title label used to present the radio favorite shows")
            case .radioShowAccess:
                return NSLocalizedString("Shows", comment: "Title label used to present the radio shows AZ and radio shows by date access buttons")
            case .tvLive:
                return NSLocalizedString("TV channels", comment: "Title label to present main TV livestreams")
            case .radioLive:
                return NSLocalizedString("Radio channels", comment: "Title label to present main radio livestreams")
            case .radioLiveSatellite:
                return NSLocalizedString("Music radios", comment: "Title label to present musical Swiss satellite radios")
            case .tvLiveCenter:
                return NSLocalizedString("Sport", comment: "Title label used to present live center medias")
            case .tvScheduledLivestreams:
                return NSLocalizedString("Events", comment: "Title label used to present scheduled livestream medias")
            }
        }
        
        var summary: String? {
            return nil
        }
        
        var label: String? {
            return nil
        }
        
        var placeholderItems: [Content.Item] {
            switch configuredSection.type {
            case .tvLiveCenter, .tvScheduledLivestreams, .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos:
                return (0..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .tvLive, .radioLive, .radioLiveSatellite:
                return (0..<defaultNumberOfLivestreamPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .radioAllShows:
                return (0..<defaultNumberOfPlaceholders).map { .showPlaceholder(index: $0) }
            case .radioFavoriteShows, .radioShowAccess:
                return []
            }
        }
        
        func publisher(triggerId: Trigger.Id, filter: SectionFiltering?) -> AnyPublisher<[Content.Item], Error>? {
            let dataProvider = SRGDataProvider.current!
            let configuration = ApplicationConfiguration.shared
            
            let vendor = configuration.vendor
            let pageSize = configuration.pageSize
            
            switch configuredSection.type {
            case let .radioLatestEpisodes(channelUid: channelUid):
                return dataProvider.radioLatestEpisodes(for: vendor, channelUid: channelUid, pageSize: pageSize, triggerId: triggerId)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioMostPopular(channelUid: channelUid):
                return dataProvider.radioMostPopularMedias(for: vendor, channelUid: channelUid, pageSize: pageSize, triggerId: triggerId)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioLatest(channelUid: channelUid):
                return dataProvider.radioLatestMedias(for: vendor, channelUid: channelUid, pageSize: pageSize, triggerId: triggerId)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioLatestVideos(channelUid: channelUid):
                return dataProvider.radioLatestVideos(for: vendor, channelUid: channelUid, pageSize: pageSize, triggerId: triggerId)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioAllShows(channelUid):
                return dataProvider.radioShows(for: vendor, channelUid: channelUid, pageSize: SRGDataProviderUnlimitedPageSize, triggerId: triggerId)
                    .map { $0.map { .show($0) } }
                    .eraseToAnyPublisher()
            case .radioFavoriteShows:
                return dataProvider.favoritesPublisher(filter: filter)
                    .map { $0.map { .show($0) } }
                    .eraseToAnyPublisher()
            case let .radioShowAccess(channelUid):
                #if os(iOS)
                return Just([.showAccess(radioChannel: configuration.radioChannel(forUid: channelUid))])
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
                #else
                return nil
                #endif
            case .tvLive:
                return dataProvider.tvLivestreams(for: vendor)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .radioLive:
                return dataProvider.regionalizedRadioLivestreams(for: vendor)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .radioLiveSatellite:
                return dataProvider.regionalizedRadioLivestreams(for: vendor, contentProviders: .swissSatelliteRadio)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvLiveCenter:
                return dataProvider.liveCenterVideos(for: vendor, pageSize: pageSize, triggerId: triggerId)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvScheduledLivestreams:
                return dataProvider.tvScheduledLivestreams(for: vendor, pageSize: pageSize, triggerId: triggerId)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            }
        }
    }
}
