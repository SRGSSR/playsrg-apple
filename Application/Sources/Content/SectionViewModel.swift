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
        let properties = configuration.properties
        return properties.displaysTitle ? properties.title : nil
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
                let rows = configuration.viewModelProperties.rows(from: removeDuplicates(in: items))
                return State.loaded(rows: rows)
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
        if deep || state.hasNoContent {
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
        let properties = configuration.properties
        
        properties.remove(Array(selectedItems))
        selectedItems.removeAll()
        
        if let analyticsDeletionHiddenEventTitle = properties.analyticsDeletionHiddenEventTitle {
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
    
    enum Header: Hashable {
        enum Size {
            case zero
            case small
            case large
        }
        
        case none
        case title(String)
        case item(Content.Item)
        case show(SRGShow)
        
        var sectionTopInset: CGFloat {
            switch self {
            case .title:
                return constant(iOS: 8, tvOS: 12)
            default:
                return 0
            }
        }
        
        var isAlwaysDisplayed: Bool {
            switch self {
            case .none, .title:
                return false
            case .item, .show:
                return true
            }
        }
    }
    
    struct Section: Hashable, Indexable {
        let id: String
        let header: Header
        
        var indexTitle: String {
            return id.uppercased()
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    typealias Item = Content.Item
    
    // Non-empty rows only. The section view namely supports optional header pinning, and the layout could raise an
    // assertion if some collection section has no items, while its header height is smaller than the layout inter group
    // spacing.
    typealias Row = NonEmptyCollectionRow<Section, Item>
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(rows: [Row])
        
        var topHeaderSize: Header.Size {
            if case let .loaded(rows: rows) = self, let firstSection = rows.first?.section {
                switch firstSection.header {
                case .title:
                    return .small
                case .item, .show:
                    return .large
                case .none:
                    return .zero
                }
            }
            else {
                return .zero
            }
        }
        
        var hasNoContent: Bool {
            if case let .loaded(rows: rows) = self {
                // Ignore `transparent` Content.Item items.
                let filteredRows = rows.filter { !$0.items.filter { $0 != .transparent }.isEmpty }
                return filteredRows.isEmpty
            }
            else {
                return true
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
    
    fileprivate static func consolidatedRows(with items: [Item], header: Header = .none) -> [Row] {
        let rowItems = (header.isAlwaysDisplayed && items.isEmpty) ? [.transparent] : items
        if let row = Row(section: Section(id: "main", header: header), items: rowItems) {
            return [row]
        }
        else {
            return []
        }
    }
    
    private static func alphabeticalRows(from groups: [(key: Character, value: [Item])]) -> [Row] {
        return groups.compactMap { character, items in
            return Row(
                section: Section(id: String(character), header: .title(String(character).uppercased())),
                items: items
            )
        }
    }
    
    /// Group items into alphabetical rows. If smart mode is enabled grouping is only performed when the result
    /// of the grouping is well-balanced.
    fileprivate static func alphabeticalRows(from items: [Item], smart: Bool) -> [Row] {
        let groups = Item.groupAlphabetically(items)
        guard groups.count > 1 else { return consolidatedRows(with: items) }
        
        if smart {
            // Group into different rows only if we have several groups whose row length median is larger than a
            // given threshold, so that we get a balanced result.
            if let medianCount = groups.map({ Double($0.value.count) }).median(), medianCount > 2 {
                return alphabeticalRows(from: groups)
            }
            else {
                return consolidatedRows(with: items)
            }
        }
        else {
            return alphabeticalRows(from: groups)
        }
    }
}

// MARK: Properties

protocol SectionViewModelProperties {
    var layout: SectionViewModel.SectionLayout { get }
    var pinToVisibleBounds: Bool { get }
    var userActivity: NSUserActivity? { get }
    
    func rows(from items: [SectionViewModel.Item]) -> [SectionViewModel.Row]
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
        
        var pinToVisibleBounds: Bool {
            #if os(iOS)
            switch contentSection.type {
            case .predefined:
                switch contentSection.presentation.type {
                case .favoriteShows:
                    return true
                default:
                    return false
                }
            default:
                // Remark: `.shows` results cannot be arranged alphabetically because of pagination; no headers.
                return false
            }
            #else
            return false
            #endif
        }
        
        var userActivity: NSUserActivity? {
            return nil
        }
        
        func rows(from items: [SectionViewModel.Item]) -> [SectionViewModel.Row] {
            switch contentSection.type {
            case .showAndMedias:
                if let firstItem = items.first, case .show = firstItem {
                    return SectionViewModel.consolidatedRows(with: Array(items.suffix(from: 1)), header: .item(firstItem))
                }
                else {
                    return SectionViewModel.consolidatedRows(with: items)
                }
            case .predefined:
                switch contentSection.presentation.type {
                case .favoriteShows:
                    return SectionViewModel.alphabeticalRows(from: items, smart: true)
                default:
                    return SectionViewModel.consolidatedRows(with: items)
                }
            default:
                // Remark: `.shows` results cannot be arranged alphabetically because of pagination.
                return SectionViewModel.consolidatedRows(with: items)
            }
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
        
        var pinToVisibleBounds: Bool {
            #if os(iOS)
            switch configuredSection {
            case .favoriteShows, .radioFavoriteShows, .radioAllShows, .tvAllShows:
                return true
            default:
                return false
            }
            #else
            return false
            #endif
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
        
        func rows(from items: [SectionViewModel.Item]) -> [SectionViewModel.Row] {
            switch configuredSection {
            case .favoriteShows, .radioFavoriteShows:
                return SectionViewModel.alphabeticalRows(from: items, smart: true)
            case .radioAllShows, .tvAllShows:
                return SectionViewModel.alphabeticalRows(from: items, smart: false)
            case let .show(show):
                return SectionViewModel.consolidatedRows(with: items, header: .show(show))
            default:
                return SectionViewModel.consolidatedRows(with: items)
            }
        }
    }
}
