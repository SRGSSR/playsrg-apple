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

    var title: String? {
        configuration.properties.title
    }

    var displaysTitle: Bool {
        configuration.properties.displaysTitle
    }

    var numberOfSelectedItems: Int {
        guard configuration.properties.supportsEdition else { return 0 }
        return selectedItems.count
    }

    init(section: Content.Section, filter: SectionFiltering?) {
        configuration = Self.Configuration(section)

        // Use property capture list (simpler code than if `self` is weakly captured). Only safe because we are
        // capturing constant values (see https://www.swiftbysundell.com/articles/swifts-closure-capturing-mechanics/)
        Publishers.Publish(onOutputFrom: reloadSignal()) { [configuration, trigger] in
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
                items.filter { !removedItems.contains($0) }
            }
            .map { items in
                let rows = configuration.viewModelProperties.rows(from: removeDuplicates(in: items))
                return State.loaded(rows: rows)
            }
            .catch { error in
                Just(State.failed(error: error))
            }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$state)
    }

    func loadMore() {
        trigger.activate(for: TriggerId.loadMore)
    }

    func reload(deep: Bool = false) {
        if deep || !state.hasContent {
            trigger.activate(for: TriggerId.reload)
        }
    }

    func select(_ item: Content.Item) {
        guard configuration.properties.supportsEdition else { return }
        selectedItems.insert(item)
    }

    func deselect(_ item: Content.Item) {
        guard configuration.properties.supportsEdition else { return }
        selectedItems.remove(item)
    }

    func clearSelection() {
        guard configuration.properties.supportsEdition else { return }
        selectedItems.removeAll()
    }

    func deleteSelection() {
        guard configuration.properties.supportsEdition else { return }

        let properties = configuration.properties
        properties.remove(Array(selectedItems))
        selectedItems.removeAll()

        if let analyticsDeletionHiddenEvent = properties.analyticsDeletionHiddenEvent(source: .selection) {
            analyticsDeletionHiddenEvent.send()
        }
    }

    /// Can be used on all platforms to minimize preprocessor need, but never emits on platforms not supporting
    /// push notifications
    func resetApplicationBadgeIfNeeded() {
        #if os(iOS)
            guard let pushService = PushService.shared else { return }

            if configuration.properties.canResetApplicationBadge {
                pushService.resetApplicationBadge()
            }
        #else
            return
        #endif
    }

    private func reloadSignal() -> AnyPublisher<Void, Never> {
        Publishers.Merge3(
            trigger.signal(activatedBy: TriggerId.reload),
            ApplicationSignal.wokenUp()
                .filter { [weak self] in
                    guard let self else { return false }
                    return !state.hasContent
                },
            ApplicationSignal.foregroundAfterTimeInBackground()
        )
        .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
        .eraseToAnyPublisher()
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
            wrappedValue.properties
        }

        var viewModelProperties: SectionViewModelProperties {
            switch wrappedValue {
            case let .content(section, type, _):
                ContentSectionProperties(contentSection: section, contentType: type)
            case let .configured(section):
                ConfiguredSectionProperties(configuredSection: section)
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

        var sectionTopInset: CGFloat {
            switch self {
            case .title:
                constant(iOS: 8, tvOS: 12)
            default:
                0
            }
        }

        var size: Size {
            switch self {
            case .title:
                .small
            case .item:
                .large
            case .none:
                .zero
            }
        }
    }

    enum Footer: Hashable {
        case none
        #if os(iOS)
            case diskInfo
        #endif
    }

    struct Section: Hashable, Indexable {
        let id: String
        let header: Header
        let footer: Footer

        var indexTitle: String {
            id.uppercased()
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

        var hasContent: Bool {
            if case let .loaded(rows: rows) = self {
                let filteredRows = rows.filter { $0.items.contains { $0 != .transparent } }
                return !filteredRows.isEmpty
            } else {
                return false
            }
        }

        var headerSize: Header.Size {
            if case let .loaded(rows: rows) = self, let firstSection = rows.first?.section {
                firstSection.header.size
            } else {
                .zero
            }
        }

        var displaysEmptyContentView: Bool {
            headerSize != .large && !hasContent
        }
    }

    enum SectionLayout: Hashable {
        case liveMediaGrid
        case mediaList
        case mediaGrid
        case showGrid
        case topicGrid
        #if os(iOS)
            case downloadGrid
            case notificationList
        #endif
    }

    enum TriggerId {
        case loadMore
        case reload
    }

    fileprivate static func consolidatedRows(with items: [Item], header: Header = .none, footer: Footer = .none) -> [Row] {
        let rowItems = (header.size == .large && items.isEmpty) ? [.transparent] : items
        if let row = Row(section: Section(id: "main", header: header, footer: footer), items: rowItems) {
            return [row]
        } else {
            return []
        }
    }

    private static func alphabeticalRows(from groups: [(key: Character, value: [Item])]) -> [Row] {
        groups.compactMap { character, items in
            Row(
                section: Section(id: String(character), header: .title(String(character).uppercased()), footer: .none),
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
            } else {
                return consolidatedRows(with: items)
            }
        } else {
            return alphabeticalRows(from: groups)
        }
    }
}

// MARK: Properties

protocol SectionViewModelProperties {
    var layout: SectionViewModel.SectionLayout { get }
    var pinHeadersToVisibleBounds: Bool { get }
    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode { get }

    func rows(from items: [SectionViewModel.Item]) -> [SectionViewModel.Row]
}

private extension SectionViewModel {
    struct ContentSectionProperties: SectionViewModelProperties {
        let contentSection: SRGContentSection
        let contentType: ContentType

        var layout: SectionViewModel.SectionLayout {
            switch contentSection.type {
            case .shows:
                return .showGrid
            case .predefined:
                switch contentSection.presentation.type {
                case .showElement, .favoriteShows:
                    return .showGrid
                case .topicSelector:
                    return .topicGrid
                case .livestreams:
                    return .liveMediaGrid
                case .swimlane, .grid:
                    return (contentSection.type == .shows) ? .showGrid : .mediaGrid
                case .availableEpisodes:
                    #if os(iOS)
                        return .mediaList
                    #else
                        return .mediaGrid
                    #endif
                default:
                    return .mediaGrid
                }
            default:
                return .mediaGrid
            }
        }

        var pinHeadersToVisibleBounds: Bool {
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

        var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
            switch contentSection.type {
            case .showAndMedias:
                .never
            default:
                .always
            }
        }

        func rows(from items: [SectionViewModel.Item]) -> [SectionViewModel.Row] {
            switch contentSection.type {
            case .showAndMedias:
                if let firstItem = items.first, case .show = firstItem {
                    SectionViewModel.consolidatedRows(with: Array(items.suffix(from: 1)), header: .item(firstItem))
                } else {
                    SectionViewModel.consolidatedRows(with: items)
                }
            case .predefined:
                switch contentSection.presentation.type {
                case .favoriteShows:
                    SectionViewModel.alphabeticalRows(from: items, smart: true)
                default:
                    SectionViewModel.consolidatedRows(with: items)
                }
            default:
                // Remark: `.shows` results cannot be arranged alphabetically because of pagination.
                SectionViewModel.consolidatedRows(with: items)
            }
        }
    }

    struct ConfiguredSectionProperties: SectionViewModelProperties {
        let configuredSection: ConfiguredSection

        var layout: SectionViewModel.SectionLayout {
            switch configuredSection {
            case .tvLive, .radioLive, .radioLiveSatellite:
                return .liveMediaGrid
            case .favoriteShows, .radioFavoriteShows, .radioAllShows, .tvAllShows, .radioAllShowsAZ:
                return .showGrid
            #if os(iOS)
                case .downloads:
                    return .downloadGrid
                case .notifications:
                    return .notificationList
            #endif
            case .availableEpisodes:
                #if os(iOS)
                    return .mediaList
                #else
                    return .mediaGrid
                #endif
            default:
                return .mediaGrid
            }
        }

        var pinHeadersToVisibleBounds: Bool {
            #if os(iOS)
                switch configuredSection {
                case .favoriteShows, .radioFavoriteShows, .radioAllShows, .tvAllShows, .radioAllShowsAZ:
                    return true
                default:
                    return false
                }
            #else
                return false
            #endif
        }

        var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
            .always
        }

        func rows(from items: [SectionViewModel.Item]) -> [SectionViewModel.Row] {
            switch configuredSection {
            case .favoriteShows, .radioFavoriteShows:
                return SectionViewModel.alphabeticalRows(from: items, smart: true)
            case .radioAllShows, .tvAllShows, .radioAllShowsAZ:
                return SectionViewModel.alphabeticalRows(from: items, smart: false)
            #if os(iOS)
                case .downloads:
                    return SectionViewModel.consolidatedRows(with: items, footer: .diskInfo)
            #endif
            default:
                return SectionViewModel.consolidatedRows(with: items)
            }
        }
    }
}
