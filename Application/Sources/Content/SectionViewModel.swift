//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import FXReachability
import SRGDataProviderCombine

// MARK: View model

final class SectionViewModel: ObservableObject {
    let configuration: SectionViewModel.Configuration
    
    @Published private(set) var state: State = .loading
    
    private let trigger = Trigger()
    private var selectedItems = Set<Content.Item>()
    private var cancellables = Set<AnyCancellable>()
    
    var title: String? {
        return configuration.properties.displaysTitle ? configuration.properties.title : nil
    }
    
    var numberOfSelectedItems: Int {
        return selectedItems.count
    }
    
    init(section: Content.Section, filter: SectionFiltering?) {
        self.configuration = SectionViewModel.Configuration(section)
        
        // Use property capture list (simpler code than if `self` is weakly captured). Only safe because we are
        // capturing constant values (see https://www.swiftbysundell.com/articles/swifts-closure-capturing-mechanics/)
        Publishers.PublishAndRepeat(onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)) { [configuration, trigger] in
            return Publishers.CombineLatest(
                configuration.properties.publisher(pageSize: ApplicationConfiguration.shared.detailPageSize,
                                                   paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore),
                                                   filter: filter)
                    .scan([]) { $0 + $1 },
                configuration.properties.interactiveUpdatesPublisher()
                    .prepend(Just([]))
                    .setFailureType(to: Error.self)
            )
            .map { items, removedItems in
                return items.filter { !removedItems.contains($0) }
            }
            .map { items in
                let uniqueItems = removeDuplicates(in: items)
                let headerItem = configuration.viewModelProperties.headerItem(from: uniqueItems)
                let rows = configuration.viewModelProperties.rows(from: uniqueItems)
                return State.loaded(headerItem: headerItem, rows: rows)
            }
            .catch { error in
                return Just(State.failed(error: error))
            }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$state)
        
        ApplicationSignal.wokenUp()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reload()
            }
            .store(in: &cancellables)
    }
    
    func loadMore() {
        trigger.activate(for: TriggerId.loadMore)
    }
    
    func reload(deep: Bool = false) {
        if deep || state.isEmpty {
            trigger.activate(for: TriggerId.reload)
        }
    }
    
    func select(_ item: Content.Item) {
        selectedItems.insert(item)
    }
    
    func deselect(_ item: Content.Item) {
        selectedItems.remove(item)
    }
    
    func clearSelection() {
        selectedItems.removeAll()
    }
    
    func deleteSelection() {
        configuration.properties.remove(Array(selectedItems))
        selectedItems.removeAll()
        
        if let analyticsDeletionHiddenEventTitle = configuration.properties.analyticsDeletionHiddenEventTitle {
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.source = AnalyticsSource.selection.rawValue
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: analyticsDeletionHiddenEventTitle, labels: labels)
        }
    }
}

// MARK: Types

extension SectionViewModel {
    struct Configuration: Hashable {
        let wrappedValue: Content.Section
        
        init(_ wrappedValue: Content.Section) {
            self.wrappedValue = wrappedValue
        }
        
        var properties: SectionProperties {
            return wrappedValue.properties
        }
        
        var viewModelProperties: SectionViewModelProperties {
            switch wrappedValue {
            case let .content(section):
                return ContentSectionProperties(contentSection: section)
            case let .configured(section):
                return ConfiguredSectionProperties(configuredSection: section)
            }
        }
    }
    
    enum HeaderItem {
        case item(Content.Item)
        case show(SRGShow)
    }
    
    struct Section: Hashable, Indexable {
        let indexTitle: String
        let title: String?
        
        init(indexTitle: String, title: String? = nil) {
            self.indexTitle = indexTitle
            self.title = title
        }
                
        func hash(into hasher: inout Hasher) {
            hasher.combine(indexTitle)
        }
    }
    
    typealias Item = Content.Item
    typealias Row = CollectionRow<Section, Item>
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(headerItem: HeaderItem?, rows: [Row])
        
        var isEmpty: Bool {
            if case let .loaded(headerItem: _, rows: rows) = self {
                return rows.isEmpty
            }
            else {
                return true
            }
        }
        
        var headerItem: HeaderItem? {
            if case let .loaded(headerItem: headerItem, rows: _) = self {
                return headerItem
            }
            else {
                return nil
            }
        }
    }
    
    enum SectionLayout: Hashable {
        case liveMediaGrid
        case mediaGrid
        case showGrid
        case topicGrid
    }
    
    enum TriggerId {
        case loadMore
        case reload
    }
}

// MARK: Properties

protocol SectionViewModelProperties {
    var layout: SectionViewModel.SectionLayout { get }
    
    func headerItem(from items: [SectionViewModel.Item]) -> SectionViewModel.HeaderItem?
    func rows(from items: [SectionViewModel.Item]) -> [SectionViewModel.Row]
    
    var userActivity: NSUserActivity? { get }
}

private extension SectionViewModel {
    struct ContentSectionProperties: SectionViewModelProperties {
        let contentSection: SRGContentSection
        
        var layout: SectionViewModel.SectionLayout {
            switch contentSection.type {
            case .medias, .showAndMedias:
                return .mediaGrid
            case .shows:
                return .showGrid
            case .predefined:
                switch contentSection.presentation.type {
                case .hero, .mediaHighlight, .mediaHighlightSwimlane, .resumePlayback, .watchLater, .personalizedProgram:
                    return .mediaGrid
                case .showHighlight, .favoriteShows:
                    return .showGrid
                case .topicSelector:
                    return .topicGrid
                case .livestreams:
                    return .liveMediaGrid
                case .swimlane, .grid:
                    return (contentSection.type == .shows) ? .showGrid : .mediaGrid
                case .none, .showAccess:
                    return .mediaGrid
                }
            case .none:
                return .mediaGrid
            }
        }
        
        func headerItem(from items: [SectionViewModel.Item]) -> SectionViewModel.HeaderItem? {
            if contentSection.type == .showAndMedias, let firstItem = items.first, case .show = firstItem {
                return .item(firstItem)
            }
            else {
                return nil
            }
        }
        
        func rows(from items: [SectionViewModel.Item]) -> [SectionViewModel.Row] {
            switch contentSection.type {
            case .showAndMedias:
                if case .show = items.first {
                    return [Row(section: Section(indexTitle: "main"), items: Array(items.suffix(from: 1)))]
                }
                else {
                    return [Row(section: Section(indexTitle: "main"), items: items)]
                }
            case .predefined:
                switch contentSection.presentation.type {
                case .favoriteShows:
                    return items.groupedAlphabetically { $0.title }
                        .map { character, items in
                            let uppercaseCharacter = String(character).uppercased()
                            return Row(section: Section(indexTitle: uppercaseCharacter, title: uppercaseCharacter), items: items)
                        }
                default:
                    return [Row(section: Section(indexTitle: "main"), items: items)]
                }
            default:
                return [Row(section: Section(indexTitle: "main"), items: items)]
            }
        }
        
        var userActivity: NSUserActivity? {
            return nil
        }
    }
    
    struct ConfiguredSectionProperties: SectionViewModelProperties {
        let configuredSection: ConfiguredSection
        
        var layout: SectionViewModel.SectionLayout {
            switch configuredSection {
            case .show, .history, .watchLater, .radioEpisodesForDay, .radioLatest, .radioLatestEpisodes, .radioLatestEpisodesFromFavorites, .radioLatestVideos, .radioMostPopular, .radioResumePlayback, .radioWatchLater, .tvEpisodesForDay, .tvLiveCenter, .tvScheduledLivestreams:
                return .mediaGrid
            case .tvLive, .radioLive, .radioLiveSatellite:
                return .liveMediaGrid
            case .favoriteShows, .radioFavoriteShows, .radioAllShows, .tvAllShows:
                return .showGrid
            case .radioShowAccess:
                return .mediaGrid
            }
        }
        
        func headerItem(from items: [SectionViewModel.Item]) -> SectionViewModel.HeaderItem? {
            switch configuredSection {
            case let .show(show):
                return .show(show)
            default:
                return nil
            }
        }
        
        func rows(from items: [SectionViewModel.Item]) -> [SectionViewModel.Row] {
            switch configuredSection {
            case .favoriteShows, .radioFavoriteShows, .radioAllShows, .tvAllShows:
                return items.groupedAlphabetically { $0.title }
                    .map { character, items in
                        let uppercaseCharacter = String(character).uppercased()
                        return Row(section: Section(indexTitle: uppercaseCharacter, title: uppercaseCharacter), items: items)
                    }
            default:
                return [Row(section: Section(indexTitle: "main"), items: items)]
            }
        }
        
        var userActivity: NSUserActivity? {
            guard let bundleIdentifier = Bundle.main.bundleIdentifier,
                  let applicationVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") else {
                return nil
            }
            
            switch configuredSection {
            case let .show(show):
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
                let suggestedInvocationPhraseFormat = (show.transmission == .radio) ? NSLocalizedString("Listen to %@", comment: "Suggested invocation phrase to listen to a show") : NSLocalizedString("Watch %@", comment: "Suggested invocation phrase to watch a show")
                userActivity.suggestedInvocationPhrase = String(format: suggestedInvocationPhraseFormat, show.title)
                #endif
                
                return userActivity
            default:
                return nil
            }
        }
    }
}
