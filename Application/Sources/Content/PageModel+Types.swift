//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGUserData

fileprivate let defaultNumberOfPlaceholders = 10

/// Common abstraction for properties associated with a section
protocol PageSectionProperties {
    var title: String? { get }
    var summary: String? { get }
    var accessibilityTitle: String { get }
    var presentationType: SRGContentPresentationType { get }
    var layout: PageModel.SectionLayout { get }
    var placeholderItems: [PageModel.Item] { get }
    var canOpenDetailPage: Bool { get }
    
    func publisher(for id: PageModel.Id) -> AnyPublisher<[PageModel.Item], Error>?
}

extension PageModel {
    enum Id {
        case video
        case audio(channel: RadioChannel)
        case live
        case topic(topic: SRGTopic)
        
        func canContain(show: SRGShow) -> Bool {
            switch self {
            case .video:
                return show.transmission == .TV
            case let .audio(channel: channel):
                return show.transmission == .radio && show.primaryChannelUid == channel.uid
            default:
                return false
            }
        }
        
        func compatibleShows(_ shows: [SRGShow]) -> [SRGShow] {
            return shows.filter { canContain(show: $0) }.sorted(by: { $0.title < $1.title })
        }
        
        func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia] {
            switch self {
            case .video:
                return medias.filter { $0.mediaType == .video }
            case let .audio(channel: channel):
                return medias.filter { $0.mediaType == .audio && $0.channel?.uid == channel.uid }
            default:
                return medias
            }
        }
    }
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(rows: [Row])
    }
    
    enum Section: Hashable {
        case content(SRGContentSection)
        case configured(ConfiguredSection)
        
        var properties: PageSectionProperties {
            switch self {
            case let .content(section):
                return section
            case let .configured(section):
                return section
            }
        }
    }
    
    enum SectionLayout: Hashable {
        case hero
        case highlight
        case mediaGrid
        case mediaSwimlane
        case showGrid
        case showSwimlane
        case topicSelector
        
        @available(tvOS, unavailable)
        case showAccess
    }
    
    // Items can appear in several sections, which is why a section parameter must be provided for each of them so
    // that each item is truly unique.
    enum Item: Hashable {
        case mediaPlaceholder(index: Int, section: Section)
        case media(_ media: SRGMedia, section: Section)
        
        case showPlaceholder(index: Int, section: Section)
        case show(_ show: SRGShow, section: Section)
        
        case topicPlaceholder(index: Int, section: Section)
        case topic(_ topic: SRGTopic, section: Section)
        
        @available(tvOS, unavailable)
        case showAccess(radioChannel: RadioChannel?, section: Section)
    }
    
    typealias Row = CollectionRow<Section, Item>
}

extension SRGContentSection: PageSectionProperties {
    var title: String? {
        if type == .predefined {
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
            case .none, .topicSelector, .swimlane, .hero, .grid, .mediaHighlight, .showHighlight:
                return nil
            }
        }
        else {
            return presentation.title
        }
    }
    
    var summary: String? {
        return presentation.summary
    }
    
    var accessibilityTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        
        // Default accessiblity titles
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
        case .topicSelector:
            return NSLocalizedString("Topics", comment: "Title label used to present TV topics")
        case .swimlane:
            return PlaySRGAccessibilityLocalizedString("Content in swimlane", "Title label used to present content in swimlane with to editorial title")
        case .hero:
            return PlaySRGAccessibilityLocalizedString("Content in featured swimlane", "Title label used to present content in featured swimlane with to editorial title")
        case .grid:
            return PlaySRGAccessibilityLocalizedString("Content in grid", "Title label used to present content in grid with to editorial title")
        case .mediaHighlight:
            return PlaySRGAccessibilityLocalizedString("A highlighted content", "Title label used to present a highlighted content with to editorial title")
        case .showHighlight:
            return PlaySRGAccessibilityLocalizedString("A highlighted show", "Title label used to present a highlighted show with to editorial title")
        case .none:
            return PlaySRGAccessibilityLocalizedString("Some content", "Title label used to present some content with to editorial title")
        }
    }
    
    var presentationType: SRGContentPresentationType {
        return presentation.type
    }
    
    var layout: PageModel.SectionLayout {
        switch presentation.type {
        case .hero:
            return .hero
        case .mediaHighlight, .showHighlight:
            return .highlight
        case .topicSelector:
            return .topicSelector
        case .showAccess:
            #if os(iOS)
            return .showAccess
            #else
            // Not supported
            return .mediaSwimlane
            #endif
        case .favoriteShows:
            return .showSwimlane
        case .swimlane:
            return (type == .shows) ? .showSwimlane : .mediaSwimlane
        case .grid:
            return (type == .shows) ? .showGrid : .mediaGrid
        case .none, .livestreams, .resumePlayback, .watchLater, .personalizedProgram:
            return .mediaSwimlane
        }
    }
    
    var placeholderItems: [PageModel.Item] {
        switch presentation.type {
        case .mediaHighlight:
            return [.mediaPlaceholder(index: 0, section: .content(self))]
        case .showHighlight:
            return [.showPlaceholder(index: 0, section: .content(self))]
        case .topicSelector:
            return (0..<defaultNumberOfPlaceholders).map { .topicPlaceholder(index: $0, section: .content(self)) }
        case .swimlane, .hero, .grid, .livestreams:
            return (0..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0, section: .content(self)) }
        case .none, .favoriteShows, .resumePlayback, .watchLater, .personalizedProgram, .showAccess:
            return []
        }
    }
    
    var canOpenDetailPage: Bool {
        return presentation.hasDetailPage
    }
    
    func publisher(for id: PageModel.Id) -> AnyPublisher<[PageModel.Item], Error>? {
        let dataProvider = SRGDataProvider.current!
        let configuration = ApplicationConfiguration.shared
        
        let vendor = configuration.vendor
        let pageSize = configuration.pageSize
        let section = PageModel.Section.content(self)
        
        switch type {
        case .medias:
            return dataProvider.medias(for: vendor, contentSectionUid: uid, pageSize: pageSize)
                .map { self.filterItems($0.medias).map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case .showAndMedias:
            return dataProvider.showAndMedias(for: vendor, contentSectionUid: uid, pageSize: pageSize)
                .map {
                    var items = [PageModel.Item]()
                    if let show = $0.showAndMedias.show {
                        items.append(.show(show, section: section))
                    }
                    items.append(contentsOf: $0.showAndMedias.medias.map { .media($0, section: section) })
                    return items
                }
                .eraseToAnyPublisher()
        case .shows:
            return dataProvider.shows(for: vendor, contentSectionUid: uid, pageSize: pageSize)
                .map { self.filterItems($0.shows).map { .show($0, section: section) } }
                .eraseToAnyPublisher()
        case .predefined:
            switch presentation.type {
            case .favoriteShows:
                return dataProvider.showsPublisher(withUrns: Array(FavoritesShowURNs()))
                    .map { id.compatibleShows($0).map { .show($0, section: section) } }
                    .eraseToAnyPublisher()
            case .personalizedProgram:
                return dataProvider.showsPublisher(withUrns: Array(FavoritesShowURNs()))
                    .map { id.compatibleShows($0).map { $0.urn } }
                    .flatMap { urns in
                        return dataProvider.latestMediasForShowsPublisher(withUrns: urns)
                    }
                    .map { $0.map { .media($0, section: section) } }
                    .eraseToAnyPublisher()
            case .livestreams:
                return dataProvider.tvLivestreams(for: vendor)
                    .map { $0.medias.map { .media($0, section: section) } }
                    .eraseToAnyPublisher()
            case .topicSelector:
                return dataProvider.tvTopics(for: vendor)
                    .map { $0.topics.map { .topic($0, section: section) } }
                    .eraseToAnyPublisher()
            case .resumePlayback:
                return dataProvider.historyPublisher()
                    .map { id.compatibleMedias($0).prefix(Int(pageSize)).map { .media($0, section: section) } }
                    .eraseToAnyPublisher()
            case .watchLater:
                return dataProvider.laterPublisher()
                    .map { id.compatibleMedias($0).prefix(Int(pageSize)).map { .media($0, section: section) } }
                    .eraseToAnyPublisher()
            case .showAccess:
                #if os(iOS)
                return Just([.showAccess(radioChannel: nil, section: section)])
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

extension ConfiguredSection: PageSectionProperties {
    var title: String? {
        switch self.type {
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
    
    var accessibilityTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        else {
            return PlaySRGAccessibilityLocalizedString("Some content", "Title label used to present some content with to editorial title")
        }
    }
    
    var presentationType: SRGContentPresentationType {
        return self.contentPresentationType
    }
    
    var layout: PageModel.SectionLayout {
        switch self.type {
        case .tvLive, .radioLive, .radioLiveSatellite, .tvLiveCenter, .tvScheduledLivestreams, .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos:
            return (self.contentPresentationType == .hero) ? .hero : .mediaSwimlane
        case .radioFavoriteShows:
            return .showSwimlane
        case .radioAllShows:
            return .showGrid
        case .radioShowAccess:
            #if os(iOS)
            return .showAccess
            #else
            // Not supported
            return .mediaSwimlane
            #endif
        }
    }
    
    var placeholderItems: [PageModel.Item] {
        switch self.type {
        case .tvLive, .radioLive, .radioLiveSatellite, .tvLiveCenter, .tvScheduledLivestreams, .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos:
            return (0..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0, section: .configured(self)) }
        case .radioAllShows:
            return (0..<defaultNumberOfPlaceholders).map { .showPlaceholder(index: $0, section: .configured(self)) }
        case .radioFavoriteShows, .radioShowAccess:
            return []
        }
    }
    
    var canOpenDetailPage: Bool {
        return layout == .mediaSwimlane
    }
    
    func publisher(for id: PageModel.Id) -> AnyPublisher<[PageModel.Item], Error>? {
        let dataProvider = SRGDataProvider.current!
        let configuration = ApplicationConfiguration.shared
        
        let vendor = configuration.vendor
        let pageSize = configuration.pageSize
        let section = PageModel.Section.configured(self)
        
        switch self.type {
        case let .radioLatestEpisodes(channelUid: channelUid):
            return dataProvider.radioLatestEpisodes(for: vendor, channelUid: channelUid, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case let .radioMostPopular(channelUid: channelUid):
            return dataProvider.radioMostPopularMedias(for: vendor, channelUid: channelUid, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case let .radioLatest(channelUid: channelUid):
            return dataProvider.radioLatestMedias(for: vendor, channelUid: channelUid, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case let .radioLatestVideos(channelUid: channelUid):
            return dataProvider.radioLatestVideos(for: vendor, channelUid: channelUid, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case let .radioAllShows(channelUid):
            return dataProvider.radioShows(for: vendor, channelUid: channelUid, pageSize: SRGDataProviderUnlimitedPageSize)
                .map { $0.shows.map { .show($0, section: section) } }
                .eraseToAnyPublisher()
        case .radioFavoriteShows:
            return dataProvider.showsPublisher(withUrns: Array(FavoritesShowURNs()))
                .map { id.compatibleShows($0).map { .show($0, section: section) } }
                .eraseToAnyPublisher()
        case let .radioShowAccess(channelUid):
            #if os(iOS)
            return Just([.showAccess(radioChannel: configuration.radioChannel(forUid: channelUid), section: section)])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            #else
            return nil
            #endif
        case .tvLive:
            return dataProvider.tvLivestreams(for: vendor)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case .radioLive:
            return dataProvider.regionalizedRadioLivestreams(for: vendor)
                .map { $0.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case .radioLiveSatellite:
            return dataProvider.regionalizedRadioLivestreams(for: vendor, contentProviders: .swissSatelliteRadio)
                .map { $0.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case .tvLiveCenter:
            return dataProvider.liveCenterVideos(for: vendor, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case .tvScheduledLivestreams:
            return dataProvider.tvScheduledLivestreams(for: vendor, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        }
    }
}

fileprivate extension SRGDataProvider {
    /// Publishes the latest 30 episodes for a show URN list
    func latestMediasForShowsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGMedia], Error> {
        return urns.publisher
            .collect(3)
            .flatMap { urns in
                return self.latestMediasForShows(withUrns: urns, filter: .episodesOnly, pageSize: 15)
            }
            .reduce([SRGMedia]()) { collectedMedias, result in
                return collectedMedias + result.medias
            }
            .map { medias in
                return Array(medias.sorted(by: { $0.date > $1.date }).prefix(30))
            }
            .eraseToAnyPublisher()
    }
    
    /// Publishes radio livestreams, replacing regional radio channels. Updates are published down the pipeline as they
    /// are retrieved.
    func regionalizedRadioLivestreams(for vendor: SRGVendor, contentProviders: SRGContentProviders = .default) -> AnyPublisher<[SRGMedia], Error> {
        #if os(iOS)
        return radioLivestreams(for: vendor, contentProviders: contentProviders)
            .flatMap { result -> AnyPublisher<[SRGMedia], Error> in
                var regionalizedMedias = result.medias
                return Publishers.MergeMany(regionalizedMedias.compactMap { media -> AnyPublisher<[SRGMedia], Error>? in
                    guard let channelUid = media.channel?.uid else { return nil }
                    
                    // If a regional stream has been selected by the user, replace the main channel media with it
                    let selectedLivestreamUrn = ApplicationSettingSelectedLivestreamURNForChannelUid(channelUid)
                    if selectedLivestreamUrn != nil && media.urn != selectedLivestreamUrn {
                        return self.radioLivestreams(for: vendor, channelUid: channelUid)
                            .map { result in
                                if let selectedMedia = ApplicationSettingSelectedLivestreamMediaForChannelUid(channelUid, result.medias) {
                                    guard let index = regionalizedMedias.firstIndex(of: media) else { return result.medias }
                                    regionalizedMedias[index] = selectedMedia
                                    return regionalizedMedias
                                }
                                else {
                                    return result.medias
                                }
                            }
                            .eraseToAnyPublisher()
                    }
                    else {
                        return Just(regionalizedMedias)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                })
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        #else
        return radioLivestreams(for: vendor, contentProviders: contentProviders)
            .map { $0.medias }
            .eraseToAnyPublisher()
        #endif
    }
    
    func historyPublisher() -> AnyPublisher<[SRGMedia], Error> {
        // TODO: Currently suboptimal: For each media we determine if playback can be resumed, an operation on
        //       the main thread and with a single user data access each time. We could  instead use a currrently
        //       private history API to combine the history entries we have and the associated medias we retrieve
        //       with a network request, calculating the progress on a background thread and with only a single
        //       user data access (the one made at the beginning). This optimization seems premature, though, so
        //       for the moment a simpler implementation is used.
        return Future<[SRGHistoryEntry], Error> { promise in
            let sortDescriptor = NSSortDescriptor(keyPath: \SRGHistoryEntry.date, ascending: false)
            SRGUserData.current!.history.historyEntries(matching: nil, sortedWith: [sortDescriptor]) { historyEntries, error in
                if let error = error {
                    promise(.failure(error))
                }
                else {
                    promise(.success(historyEntries ?? []))
                }
            }
        }
        .map { historyEntries in
            historyEntries.compactMap { $0.uid }
        }
        .flatMap { urns in
            return self.medias(withUrns: urns, pageSize: 50 /* Use largest page size */)
        }
        .receive(on: DispatchQueue.main)
        .map { $0.medias.filter { HistoryCanResumePlaybackForMedia($0) } }
        .eraseToAnyPublisher()
    }
    
    func laterPublisher() -> AnyPublisher<[SRGMedia], Error> {
        return Future<[SRGPlaylistEntry], Error> { promise in
            let sortDescriptor = NSSortDescriptor(keyPath: \SRGPlaylistEntry.date, ascending: false)
            SRGUserData.current!.playlists.playlistEntriesInPlaylist(withUid: SRGPlaylistUid.watchLater.rawValue, matching: nil, sortedWith: [sortDescriptor]) { playlistEntries, error in
                if let error = error {
                    promise(.failure(error))
                }
                else {
                    promise(.success(playlistEntries ?? []))
                }
            }
        }
        .map { playlistEntries in
            playlistEntries.compactMap { $0.uid }
        }
        .flatMap { urns in
            return self.medias(withUrns: urns, pageSize: 50 /* Use largest page size */)
        }
        .map { $0.medias }
        .eraseToAnyPublisher()
    }
    
    func showsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGShow], Error> {
        let pagePublisher = CurrentValueSubject<SRGDataProvider.Shows.Page?, Never>(nil)
        
        return pagePublisher
            .flatMap { page in
                return page != nil ? self.shows(at: page!) : self.shows(withUrns: urns, pageSize: 50 /* Use largest page size */)
            }
            .handleEvents(receiveOutput: { result in
                if let nextPage = result.nextPage {
                    pagePublisher.value = nextPage
                }
                else {
                    pagePublisher.send(completion: .finished)
                }
            })
            .reduce([SRGShow]()) { collectedShows, result in
                return collectedShows + result.shows
            }
            .eraseToAnyPublisher()
    }
}
