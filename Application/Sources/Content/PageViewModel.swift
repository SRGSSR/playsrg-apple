//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SwiftUI

// MARK: View model

final class PageViewModel: Identifiable, ObservableObject {
    let id: Id

    @Published private(set) var state: State = .loading
    @Published private(set) var serviceMessage: ServiceMessage?

    @Published private(set) var displayedShow: SRGShow?

    private let trigger = Trigger()

    init(id: Id) {
        self.id = id

        Publishers.Publish(onOutputFrom: reloadSignal()) { [weak self] in
            Self.pagePublisher(id: id)
                .map { page in
                    Publishers.AccumulateLatestMany(page.sections.map { section in
                        Publishers.PublishAndRepeat(onOutputFrom: Self.rowReloadSignal(for: section, trigger: self?.trigger)) {
                            Self.rowPublisher(id: id,
                                              section: section,
                                              pageSize: Self.pageSize(for: section, in: page.sections),
                                              paginatedBy: self?.trigger.signal(activatedBy: TriggerId.loadMore(section: section)))
                                .replaceError(with: Self.fallbackRow(for: section, state: self?.state))
                                .prepend(Self.placeholderRow(for: section, state: self?.state))
                        }
                    })
                    .map { (page, $0) }
                    .eraseToAnyPublisher()
                }
                .switchToLatest()
                .map { page, rows in
                    State.loaded(rows: rows.filter { !$0.isEmpty }, pageUid: page.uid)
                }
                .catch { error in
                    Just(State.failed(error: error, pageUid: self?.state.pageUid))
                }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$state)

        Publishers.PublishAndRepeat(onOutputFrom: reloadSignal()) {
            URLSession.shared.dataTaskPublisher(for: ApplicationConfiguration.shared.serviceMessageUrl)
                .map(\.data)
                .decode(type: ServiceMessage.self, decoder: JSONDecoder())
                .map { Optional($0) }
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .assign(to: &$serviceMessage)

        if case let .show(show) = id {
            displayedShow = show

            // The show page needs `topics` which could be available only in the show request.
            SRGDataProvider.current!.show(withUrn: show.urn)
                .map { $0 }
                .replaceError(with: show)
                .receive(on: DispatchQueue.main)
                .assign(to: &$displayedShow)
        }
    }

    func loadMore() {
        if let lastSection = state.sections.last, Self.hasLoadMore(for: lastSection, in: state.sections) {
            trigger.activate(for: TriggerId.loadMore(section: lastSection))
        }
    }

    func reload(deep: Bool = false) {
        if deep || state.sections.isEmpty {
            trigger.activate(for: TriggerId.reload)
        } else {
            for section in state.sections where !Self.hasLoadMore(for: section, in: state.sections) {
                trigger.activate(for: TriggerId.reloadSection(section))
            }
        }
    }

    private func reloadSignal() -> AnyPublisher<Void, Never> {
        return Publishers.Merge4(
            trigger.signal(activatedBy: TriggerId.reload),
            ApplicationSignal.wokenUp()
                .filter { [weak self] in
                    guard let self else { return false }
                    return state.sections.isEmpty
                },
            ApplicationSignal.foregroundAfterTimeInBackground(),
            ApplicationSignal.applicationConfigurationUpdate()
                .filter { [weak self] in
                    guard let self else { return false }
                    return id.isConfigured
                }
        )
        .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
        .eraseToAnyPublisher()
    }

    private static func rowReloadSignal(for section: Section, trigger: Trigger?) -> AnyPublisher<Void, Never> {
        return Publishers.Merge(
            section.properties.reloadSignal() ?? PassthroughSubject<Void, Never>().eraseToAnyPublisher(),
            trigger?.signal(activatedBy: TriggerId.reloadSection(section)) ?? PassthroughSubject<Void, Never>().eraseToAnyPublisher()
        )
        .eraseToAnyPublisher()
    }

    private static func hasLoadMore(for section: Section, in sections: [Section]) -> Bool {
        if section == sections.last && section.viewModelProperties.hasLoadMore {
            return true
        } else {
            return false
        }
    }

    private static func pageSize(for section: Section, in sections: [Section]) -> UInt {
        let configuration = ApplicationConfiguration.shared
        return hasLoadMore(for: section, in: sections) ? configuration.detailPageSize : configuration.pageSize
    }

    private static func placeholderRow(for section: Section, state: State?) -> Row {
        if let row = state?.rows.first(where: { $0.section == section }) {
            return row
        } else {
            return Row(section: section, items: Self.placeholderRowItems(for: section))
        }
    }

    private static func fallbackRow(for section: Section, state: State?) -> Row {
        if let row = state?.rows.first(where: { $0.section == section }) {
            return row
        } else {
            return Row(section: section, items: [])
        }
    }

    private static func placeholderRowItems(for section: Section) -> [Item] {
        return section.properties.placeholderRowItems.map { Item(.item($0), in: section) }
    }
}

// MARK: Types

extension PageViewModel {
    enum Id: SectionFiltering {
        case video
        case audio(channel: RadioChannel?)
        case live
        case topic(_ topic: SRGTopic)
        case show(_ show: SRGShow)
        case page(_ page: SRGContentPage)

        #if os(iOS)
            var sharingItem: SharingItem? {
                switch self {
                case let .show(show):
                    return SharingItem(for: show)
                case let .page(page):
                    return SharingItem(for: page)
                default:
                    return nil
                }
            }
        #endif

        var supportsCastButton: Bool {
            switch self {
            case .video, .audio, .live:
                return true
            default:
                return false
            }
        }

        var isConfigured: Bool {
            switch self {
            case .audio, .live:
                return true
            default:
                return false
            }
        }

        var title: String? {
            switch self {
            case .video:
                return NSLocalizedString("Videos", comment: "Title displayed at the top of the video view")
            case .audio:
                return NSLocalizedString("Audios", comment: "Title displayed at the top of the audio view")
            case .live:
                return NSLocalizedString("Livestreams", comment: "Title displayed at the top of the livestreams view")
            case let .topic(topic):
                return topic.title
            case let .show(show):
                return show.title
            case let .page(page):
                return page.title
            }
        }

        var analyticsPageViewTitle: String {
            switch self {
            case .video, .audio, .live:
                return AnalyticsPageTitle.home.rawValue
            case let .topic(topic):
                return topic.title
            case let .show(show):
                return show.title
            case let .page(page):
                return page.title
            }
        }

        var analyticsPageViewType: String {
            switch self {
            case .video, .audio, .page:
                return AnalyticsPageType.landingPage.rawValue
            case .live:
                return AnalyticsPageType.live.rawValue
            case .topic, .show:
                return AnalyticsPageType.overview.rawValue
            }
        }

        var analyticsPageViewLevels: [String]? {
            switch self {
            case .video:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
            case let .audio(channel: channel):
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.audio.rawValue, channel?.name].compactMap { $0 }
            case .live:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.live.rawValue]
            case .topic:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue, AnalyticsPageLevel.topic.rawValue]
            case let .show(show):
                let level2 = show.transmission == .radio ? AnalyticsPageLevel.audio.rawValue : AnalyticsPageLevel.video.rawValue
                return [AnalyticsPageLevel.play.rawValue, level2, AnalyticsPageLevel.show.rawValue]
            case let .page(page):
                let level3 = page.type == .microPage ? AnalyticsPageLevel.microPage.rawValue : AnalyticsPageLevel.pacPage.rawValue
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue, level3]
            }
        }

        func analyticsPageViewLabels(pageUid: String?) -> SRGAnalyticsPageViewLabels? {
            guard let pageUid else { return nil }

            let pageViewLabels = SRGAnalyticsPageViewLabels()
            pageViewLabels.customInfo = ["pac_page_id": pageUid]
            return pageViewLabels
        }

        func canContain(show: SRGShow) -> Bool {
            switch self {
            case .video:
                return show.transmission == .TV
            case let .audio(channel: channel):
                if let channel {
                    return show.transmission == .radio && show.primaryChannelUid == channel.uid
                } else {
                    return show.transmission == .radio
                }
            default:
                return false
            }
        }

        func compatibleShows(_ shows: [SRGShow]) -> [SRGShow] {
            return shows.filter { canContain(show: $0) }
        }

        func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia] {
            switch self {
            case .video:
                return medias.filter { $0.mediaType == .video }
            case let .audio(channel: channel):
                if let channel {
                    return medias.filter { $0.mediaType == .audio && ($0.channel?.uid == channel.uid || $0.show?.primaryChannelUid == channel.uid) }
                } else {
                    return medias.filter { $0.mediaType == .audio }
                }
            default:
                return medias
            }
        }
    }

    enum State {
        case loading
        case failed(error: Error, pageUid: String?)
        case loaded(rows: [Row], pageUid: String?)

        var rows: [Row] {
            if case let .loaded(rows: rows, _) = self {
                return rows
            } else {
                return []
            }
        }

        var sections: [Section] {
            return rows.map(\.section)
        }

        var isEmpty: Bool {
            return rows.isEmpty
        }

        var pageUid: String? {
            switch self {
            case .loading:
                return nil
            case let .failed(_, pageUid: pageUid):
                return pageUid
            case let .loaded(_, pageUid: pageUid):
                return pageUid
            }
        }
    }

    enum SectionLayout: Hashable {
        case heroStage
        case highlight
        case headline
        case element
        case elementSwimlane
        case liveMediaGrid
        case liveMediaSwimlane
        case mediaGrid
        case mediaList
        case mediaSwimlane
        case showGrid
        case showSwimlane
        case topicSelector
        #if os(iOS)
            case showAccess
        #endif
    }

    fileprivate struct Page: Hashable {
        let uid: String?
        let sections: [Section]
    }

    struct Section: Hashable {
        let wrappedValue: Content.Section
        let index: Int // TODO: Remove when all pages are configured with PAC

        init(_ wrappedValue: Content.Section, index: Int) {
            self.wrappedValue = wrappedValue
            self.index = index
        }

        var properties: SectionProperties {
            return wrappedValue.properties
        }

        var viewModelProperties: PageViewModelProperties {
            switch wrappedValue {
            case let .content(section, _, _):
                return ContentSectionProperties(contentSection: section)
            case let .configured(section):
                return ConfiguredSectionProperties(configuredSection: section, index: index)
            }
        }
    }

    struct Item: Hashable {
        enum WrappedValue: Hashable {
            case item(Content.Item)
            case more
        }

        let wrappedValue: WrappedValue
        let section: Section

        init(_ wrappedValue: WrappedValue, in section: Section) {
            self.wrappedValue = wrappedValue
            self.section = section
        }
    }

    typealias Row = CollectionRow<Section, Item>

    enum TriggerId: Hashable {
        case reload
        case reloadSection(Section)
        case loadMore(section: Section)
    }
}

// MARK: Header and navigation

extension PageViewModel {
    #if os(iOS)
        var isHeaderWithTitle: Bool {
            return displayedTitle != nil || displayedShow != nil
        }

        var isLargeTitleDisplayMode: Bool {
            if isHeaderWithTitle {
                return false
            } else {
                // Avoid iOS automatic scroll insets / offset bugs occurring if large titles are desired by a view controller
                // but the navigation bar is hidden. The scroll insets are incorrect and sometimes the scroll offset might
                // be incorrect at the top.
                return !isNavigationBarHidden
            }
        }

        var isNavigationBarHidden: Bool {
            switch id {
            case .video:
                return true
            case let .audio(channel: channel):
                return channel == nil
            default:
                return false
            }
        }
    #endif

    var primaryColor: Color {
        switch id {
        case let .topic(topic):
            return ApplicationConfiguration.shared.topicColors(for: topic) != nil ? .white : .srgGrayD2
        case .show:
            guard let topic = displayedShow?.topics?.first else { return .srgGrayD2 }
            return ApplicationConfiguration.shared.topicColors(for: topic) != nil ? .white : .srgGrayD2
        default:
            return .srgGrayD2
        }
    }

    var secondaryColor: Color {
        return .srgGray96
    }

    var displayedTitle: String? {
        switch id {
        case let .page(page):
            return page.title
        case let .topic(topic):
            return topic.title
        default:
            return nil
        }
    }

    var displayedTitleDescription: String? {
        if case let .page(page) = id {
            return page.summary
        } else {
            return nil
        }
    }

    var displayedTitleTextAlignment: TextAlignment {
        if case .topic = id {
            return constant(iOS: .leading, tvOS: .center)
        } else {
            return .leading
        }
    }

    var displayedTitleNeedsTopPadding: Bool {
        if case let .topic(topic) = id, ApplicationConfiguration.shared.topicColors(for: topic) != nil {
            return constant(iOS: true, tvOS: false)
        } else {
            return false
        }
    }

    var displayedGradientTopic: SRGTopic? {
        switch id {
        case let .topic(topic):
            return topic
        case .show:
            guard let topic = displayedShow?.topics?.first else { return nil }
            return topic
        default:
            return nil
        }
    }

    var displayedGradientTopicStyle: TopicGradientView.Style? {
        switch id {
        case .topic:
            return .topicPage
        case .show:
            return .showPage
        default:
            return nil
        }
    }
}

// MARK: User activity

extension PageViewModel {
    var userActivity: NSUserActivity? {
        {
            guard let bundleIdentifier = Bundle.main.bundleIdentifier,
                  let applicationVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            else {
                return nil
            }

            if case let .show(show) = id {
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: show, requiringSecureCoding: false) else { return nil }
                let userActivity = NSUserActivity(activityType: bundleIdentifier.appending(".displaying"))
                userActivity.title = String(format: NSLocalizedString("Display %@ episodes", comment: "User activity title when displaying a show page"), show.title)
                userActivity.webpageURL = ApplicationConfiguration.shared.sharingURL(for: show)
                userActivity.addUserInfoEntries(from: [
                    "URNString": show.urn,
                    "SRGShowData": data,
                    "applicationVersion": applicationVersion
                ])
                #if os(iOS)
                    userActivity.isEligibleForPrediction = true
                    userActivity.persistentIdentifier = show.urn
                    let suggestedInvocationPhraseFormat = show.transmission == .radio ? NSLocalizedString("Listen to %@", comment: "Suggested invocation phrase to listen to a show") : NSLocalizedString("Watch %@", comment: "Suggested invocation phrase to watch a show")
                    userActivity.suggestedInvocationPhrase = String(format: suggestedInvocationPhraseFormat, show.title)
                #endif
                return userActivity
            } else {
                return nil
            }
        }()
    }
}

// MARK: Publishers

private extension PageViewModel {
    static func pagePublisher(id: Id) -> AnyPublisher<Page, Error> {
        switch id {
        case .video:
            return SRGDataProvider.current!.contentPage(for: ApplicationConfiguration.shared.vendor, product: .playVideo)
                .map { Page(uid: $0.uid, sections: $0.sections.enumeratedMap { Section(.content($0, type: .videoOrTV), index: $1) }) }
                .eraseToAnyPublisher()
        case let .topic(topic):
            return SRGDataProvider.current!.contentPage(for: topic.vendor, topicWithUrn: topic.urn)
                // FIXME: is topic page always videoOrTV content type?
                .map { Page(uid: $0.uid, sections: $0.sections.enumeratedMap { Section(.content($0, type: .videoOrTV), index: $1) }) }
                .eraseToAnyPublisher()
        case let .show(show):
            if show.transmission == .TV && !ApplicationConfiguration.shared.isPredefinedShowPagePreferred {
                return SRGDataProvider.current!.contentPage(for: show.vendor, product: show.transmission == .radio ? .playAudio : .playVideo, showWithUrn: show.urn)
                    .map { Page(uid: $0.uid, sections: $0.sections.enumeratedMap { Section(.content($0, type: show.play_contentType, show: show), index: $1) }) }
                    .eraseToAnyPublisher()
            } else {
                return Just(Page(uid: nil, sections: [Section(.configured(.availableEpisodes(show)), index: 0)]))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        case let .page(page):
            return SRGDataProvider.current!.contentPage(for: page.vendor, uid: page.uid)
                // FIXME: is page always videoOrTV content type?
                .map { Page(uid: $0.uid, sections: $0.sections.enumeratedMap { Section(.content($0, type: .videoOrTV), index: $1) }) }
                .eraseToAnyPublisher()
        case let .audio(channel: channel):
            if let channel, let uid = channel.contentPageId, ApplicationSettingAudioHomepageOption() == .curatedMany {
                return SRGDataProvider.current!.contentPage(for: ApplicationConfiguration.shared.vendor, uid: uid)
                    .map { Page(uid: $0.uid, sections: $0.sections.enumeratedMap { Section(.content($0, type: .audioOrRadio), index: $1) }) }
                    .eraseToAnyPublisher()
            } else if let channel {
                return Just(Page(uid: nil, sections: channel.configuredSections().enumeratedMap { Section(.configured($0), index: $1) }))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } else {
                return SRGDataProvider.current!.contentPage(for: ApplicationConfiguration.shared.vendor, product: .playAudio)
                    .map { Page(uid: $0.uid, sections: $0.sections.enumeratedMap { Section(.content($0, type: .audioOrRadio), index: $1) }) }
                    .eraseToAnyPublisher()
            }
        case .live:
            return Just(Page(uid: nil, sections: ApplicationConfiguration.shared.liveConfiguredSections.enumeratedMap { Section(.configured($0), index: $1) }))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }

    static func rowPublisher(id: Id, section: Section, pageSize: UInt, paginatedBy paginator: Trigger.Signal?) -> AnyPublisher<Row, Error> {
        if let highlight = section.properties.rowHighlight {
            return section.properties.publisher(pageSize: pageSize, paginatedBy: paginator, filter: id)
                .map { items in
                    guard let firstItem = items.first else { return Row(section: section, items: []) }

                    let highlightedItem = section.properties.hasHighlightedItem ? firstItem : nil
                    let item = Item(.item(.highlight(highlight, item: highlightedItem)), in: section)
                    return Row(section: section, items: [item])
                }
                .eraseToAnyPublisher()
        } else {
            return Publishers.CombineLatest(
                section.properties.publisher(pageSize: pageSize, paginatedBy: paginator, filter: id)
                    .scan([]) { $0 + $1 },
                section.properties.interactiveUpdatesPublisher()
                    .prepend(Just([]))
                    .setFailureType(to: Error.self)
            )
            .map { items, removedItems in
                items.filter { !removedItems.contains($0) }
            }
            .map { rowItems(removeDuplicates(in: $0), in: section) }
            .map { Row(section: section, items: $0) }
            .eraseToAnyPublisher()
        }
    }

    static func rowItems(_ items: [Content.Item], in section: Section) -> [Item] {
        var rowItems = items.map { Item(.item($0), in: section) }
        #if os(tvOS)
            if !rowItems.isEmpty,
               section.viewModelProperties.canOpenPage || ApplicationSettingSectionWideSupportEnabled(),
               section.viewModelProperties.hasMoreRowItem {
                rowItems.append(Item(.more, in: section))
            }
        #endif
        return rowItems
    }
}

// MARK: Properties

protocol PageViewModelProperties {
    var layout: PageViewModel.SectionLayout { get }
    var canOpenPage: Bool { get }
}

extension PageViewModelProperties {
    #if os(tvOS)
        var hasMoreRowItem: Bool {
            switch layout {
            case .mediaSwimlane, .showSwimlane, .elementSwimlane:
                return true
            default:
                return false
            }
        }
    #endif

    var hasLoadMore: Bool {
        switch layout {
        case .mediaGrid, .mediaList, .showGrid, .liveMediaGrid:
            return true
        default:
            return false
        }
    }
}

private extension PageViewModel {
    struct ContentSectionProperties: PageViewModelProperties {
        let contentSection: SRGContentSection

        private var presentation: SRGContentPresentation {
            return contentSection.presentation
        }

        var layout: PageViewModel.SectionLayout {
            switch presentation.type {
            case .heroStage:
                return .heroStage
            case .highlight:
                return (Highlight(from: contentSection) != nil) ? .highlight : .mediaSwimlane
            case .showPromotion:
                return (Highlight(from: contentSection) != nil) ? .highlight : .showSwimlane
            case .mediaElement, .showElement:
                return .element
            case .mediaElementSwimlane:
                return .elementSwimlane
            case .topicSelector:
                return .topicSelector
            #if os(iOS)
                case .showAccess:
                    return .showAccess
            #endif
            case .favoriteShows:
                return .showSwimlane
            case .swimlane:
                return (contentSection.type == .shows) ? .showSwimlane : .mediaSwimlane
            case .grid:
                return (contentSection.type == .shows) ? .showGrid : .mediaGrid
            case .availableEpisodes:
                #if os(iOS)
                    return .mediaList
                #else
                    return .mediaGrid
                #endif
            case .livestreams:
                return .liveMediaSwimlane
            default:
                return .mediaSwimlane
            }
        }

        var canOpenPage: Bool {
            switch presentation.type {
            case .favoriteShows, .myProgram, .continueWatching, .topicSelector, .watchLater:
                return true
            default:
                if presentation.contentLink != nil {
                    return true
                } else {
                    return false
                }
            }
        }
    }

    struct ConfiguredSectionProperties: PageViewModelProperties {
        let configuredSection: ConfiguredSection
        let index: Int // TODO: Remove when all pages are configured with PAC

        var layout: PageViewModel.SectionLayout {
            switch configuredSection {
            case .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos:
                return index == 0 ? .headline : .mediaSwimlane
            case .tvLive, .radioLive, .radioLiveSatellite:
                #if os(iOS)
                    return .liveMediaGrid
                #else
                    return .liveMediaSwimlane
                #endif
            case .favoriteShows, .radioFavoriteShows:
                return .showSwimlane
            case .radioAllShows, .tvAllShows:
                return .showGrid
            #if os(iOS)
                case .radioShowAccess:
                    return .showAccess
            #endif
            case .availableEpisodes:
                #if os(iOS)
                    return .mediaList
                #else
                    return .mediaGrid
                #endif
            default:
                return .mediaSwimlane
            }
        }

        var canOpenPage: Bool {
            return layout == .mediaSwimlane || layout == .showSwimlane
        }
    }
}
