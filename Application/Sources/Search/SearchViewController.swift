//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAnalytics
import SRGAppearanceSwift
import SRGDataProviderModel
import SwiftUI
import UIKit

// MARK: View controller

final class SearchViewController: UIViewController {
    private var model = SearchViewModel()
        
    private var cancellables = Set<AnyCancellable>()
    
    private var dataSource: UICollectionViewDiffableDataSource<SearchViewModel.Section, SearchViewModel.Item>!
    
    private weak var collectionView: UICollectionView!
    private weak var emptyView: HostView<EmptyView>!
    
#if os(iOS)
    private weak var filtersBarButtonItem: UIBarButtonItem?
    private weak var refreshControl: UIRefreshControl!
    private var defaultLeftView: UIView?        // strong
    
    private var refreshTriggered = false
    private var searchUpdateInhibited = false
    private var previousYContentOffset: CGFloat = 0
#endif
    private weak var searchController: UISearchController?
    
    private static let itemSpacing: CGFloat = constant(iOS: 8, tvOS: 40)
    
    private static func snapshot(from state: SearchViewModel.State) -> NSDiffableDataSourceSnapshot<SearchViewModel.Section, SearchViewModel.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<SearchViewModel.Section, SearchViewModel.Item>()
        if case let .loaded(rows: rows, suggestions: _) = state {
            for row in rows {
                snapshot.appendSections([row.section])
                snapshot.appendItems(row.items, toSection: row.section)
            }
        }
        return snapshot
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        title = TitleForApplicationSection(.search)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let emptyView = HostView<EmptyView>(frame: .zero)
        collectionView.backgroundView = emptyView
        self.emptyView = emptyView
        
#if os(iOS)
        let refreshControl = RefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.insertSubview(refreshControl, at: 0)
        self.refreshControl = refreshControl
#endif
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<ItemCell>, SearchViewModel.Item> { cell, _, item in
            cell.content = ItemCell(item: item)
            // Avoid pausing a loading animation when the user taps the parent cell
            // See https://stackoverflow.com/questions/27904177/uiimageview-animation-stops-when-user-touches-screen/29330962
            cell.isUserInteractionEnabled = (item != .loading)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        let sectionHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<SectionHeaderView>>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] view, _, indexPath in
            guard let self = self else { return }
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            view.content = SectionHeaderView(section: section, settings: self.model.settings)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: sectionHeaderViewRegistration, for: indexPath)
        }
        
        model.$state
            .sink { [weak self] state in
                guard let self = self else { return }
                self.reloadData(for: state)
#if os(tvOS)
                guard let searchController = self.searchController else { return }
                if case let .loaded(rows: _, suggestions: suggestions) = state {
                    if let suggestions = suggestions {
                        searchController.searchSuggestions = suggestions.map { UISearchSuggestionItem(localizedSuggestion: $0.text) }
                    }
                    else {
                        searchController.searchSuggestions = nil
                    }
                }
                else {
                    searchController.searchSuggestions = nil
                }
#endif
            }
            .store(in: &cancellables)
        
#if os(iOS)
        navigationItem.largeTitleDisplayMode = .always
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.showsSearchResultsController = true
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        self.searchController = searchController
        
        let searchBar = searchController.searchBar
        object_setClass(searchBar, SearchBar.self)
        
        searchBar.placeholder = NSLocalizedString("Shows, Topics, and More", comment: "Search placeholder text")
        searchBar.autocapitalizationType = .none
        searchBar.tintColor = .white
        searchBar.delegate = self
        
        definesPresentationContext = true
        
        model.$query
            .removeDuplicates()         // Prevent recursive updates
            .sink { query in
                searchBar.text = query
            }
            .store(in: &cancellables)
        model.$settings
            .sink { [weak self] settings in
                self?.updateSearchSettingsButton(for: settings)
            }
            .store(in: &cancellables)
#endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.reload()
#if os(tvOS)
        searchController?.searchControllerObservedScrollView = collectionView
#else
        deselectItems(in: collectionView, animated: animated)
#endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if os(tvOS)
        tabBarObservedScrollView = collectionView
#endif
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
#if os(iOS)
        // Dismiss to avoid retain cycle if the search was entered once, see https://stackoverflow.com/a/33619501/760435
        searchController?.dismiss(animated: false, completion: nil)
#endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
#if os(iOS)
        searchController?.searchBar.resignFirstResponder()
#endif
    }
    
#if os(iOS)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
    
    private func updateSearchSettingsButton(for settings: SRGMediaSearchSettings) {
        guard !ApplicationConfiguration.shared.areSearchSettingsHidden else {
            navigationItem.rightBarButtonItem = nil
            return
        }
        
        if filtersBarButtonItem == nil {
            let filtersButton = UIButton(type: .custom)
            filtersButton.addTarget(self, action: #selector(showSettings(_:)), for: .touchUpInside)
            
            if let titleLabel = filtersButton.titleLabel {
                titleLabel.font = SRGFont.font(family: .text, weight: .regular, size: 16)
                
                // Trick to avoid incorrect truncation when Bold text has been enabled in system settings
                // See https://developer.apple.com/forums/thread/125492
                titleLabel.lineBreakMode = .byClipping
            }
            filtersButton.setTitle(NSLocalizedString("Filters", comment: "Filters button title"), for: .normal)
            filtersButton.setTitleColor(.srgGrayC7, for: .normal)
            filtersButton.setTitleColor(.gray, for: .highlighted)
            
            // See https://stackoverflow.com/a/25559946/760435
            let inset: CGFloat = 2
            filtersButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
            filtersButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)
            filtersButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
            
            let filtersBarButtonItem = UIBarButtonItem(customView: filtersButton)
            navigationItem.rightBarButtonItem = filtersBarButtonItem
            self.filtersBarButtonItem = filtersBarButtonItem
        }
        
        if let filtersButton = filtersBarButtonItem?.customView as? UIButton {
            let image = !SearchViewModel.areDefaultSettings(settings) ? UIImage(named: "filter_on") : UIImage(named: "filter_off")
            filtersButton.setImage(image, for: .normal)
        }
    }
    
    @objc private func closeKeyboard(_ sender: Any) {
        searchController?.searchBar.resignFirstResponder()
    }
    
    @objc private func showSettings(_ sender: Any) {
        searchController?.searchBar.resignFirstResponder()
        
        let settingsViewController = SearchSettingsViewController(query: model.query, settings: model.settings)
        settingsViewController.delegate = self
        
        let backgroundColor: UIColor? = UIDevice.current.userInterfaceIdiom == .pad ? .play_popoverGrayBackground : nil
        let navigationController = NavigationController(rootViewController: settingsViewController,
                                                        tintColor: .white,
                                                        backgroundColor: backgroundColor,
                                                        statusBarStyle: .lightContent)
        navigationController.modalPresentationStyle = .popover
        
        if let popoverPresentationController = navigationController.popoverPresentationController {
            popoverPresentationController.backgroundColor = .play_popoverGrayBackground
            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.barButtonItem = filtersBarButtonItem
        }
        
        present(navigationController, animated: true)
    }
#endif
    
    private func reloadData(for state: SearchViewModel.State) {
        switch state {
        case .loading:
            emptyView.content = EmptyView(state: .loading, insets: Self.emptyViewInsets)
        case let .failed(error: error):
            emptyView.content = EmptyView(state: .failed(error: error), insets: Self.emptyViewInsets)
        case .loaded:
            if !state.hasContent {
                let type: EmptyView.`Type` = model.isSearching ? .search : .searchTutorial
                emptyView.content = EmptyView(state: .empty(type: type), insets: Self.emptyViewInsets)
            }
            else {
                emptyView.content = nil
            }
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            // Can be triggered on a background thread. Layout is updated on the main thread.
            self.dataSource.apply(Self.snapshot(from: state)) {
#if os(iOS)
                // Avoid stopping scrolling.
                // See http://stackoverflow.com/a/31681037/760435
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
#endif
            }
        }
    }
    
#if os(iOS)
    @objc private func pullToRefresh(_ refreshControl: RefreshControl) {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        refreshTriggered = true
    }
#endif
}

// MARK: Instantiation

extension SearchViewController {
    @objc static func viewController() -> UIViewController {
#if os(tvOS)
        let searchViewController = SearchViewController()
        let searchController = UISearchController(searchResultsController: searchViewController)
        searchViewController.searchController = searchController
        searchController.searchResultsUpdater = searchViewController
        return UISearchContainerViewController(searchController: searchController)
#else
        return SearchViewController()
#endif
    }
}

// MARK: Keyboard shorcuts

#if os(iOS)
extension SearchViewController {
    private var searchKeyCommand: UIKeyCommand {
        let keyCommand = UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(search(_:)))
        keyCommand.discoverabilityTitle = NSLocalizedString("Search", comment: "Search shortcut label")
        return keyCommand
    }
    
    @objc private func search(_ commmand: UIKeyCommand) {
        searchController?.searchBar.becomeFirstResponder()
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [searchKeyCommand]
    }
}
#endif

// MARK: Protocols

extension SearchViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        return collectionView != nil ? [collectionView] : nil
    }
    
    var play_paddingContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: Self.layoutVerticalMargin, left: 0, bottom: Self.layoutVerticalMargin, right: 0)
    }
}

extension SearchViewController: ScrollableContent {
    var play_scrollableView: UIScrollView? {
        return collectionView
    }
}

extension SearchViewController: SRGAnalyticsViewTracking {
    var srg_pageViewTitle: String {
        return AnalyticsPageTitle.home.rawValue
    }
    
    var srg_pageViewLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.search.rawValue]
    }
}

#if os(iOS)
extension SearchViewController: PlayApplicationNavigation {
    func open(_ applicationSectionInfo: ApplicationSectionInfo) -> Bool {
        guard applicationSectionInfo.applicationSection == .search else { return false }
        
        model.query = applicationSectionInfo.options?[ApplicationSectionOptionKey.searchQueryKey] as? String ?? ""
        
        let settings = SRGMediaSearchSettings()
        if let mediaType = applicationSectionInfo.options?[ApplicationSectionOptionKey.searchMediaTypeOptionKey] as? Int {
            settings.mediaType = SRGMediaType(rawValue: mediaType) ?? .none
        }
        model.settings = settings
        
        searchController?.searchBar.resignFirstResponder()
        return true
    }
}

extension SearchViewController: SearchSettingsViewControllerDelegate {
    func searchSettingsViewController(_ searchSettingsViewController: SearchSettingsViewController, didUpdate settings: SRGMediaSearchSettings) {
        model.settings = settings
    }
}

extension SearchViewController: TabBarActionable {
    func performActiveTabAction(animated: Bool) {
        collectionView?.play_scrollToTop(animated: animated)
    }
}
#endif

extension SearchViewController: UICollectionViewDelegate {
#if os(iOS)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        switch item {
        case let .media(media):
            play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
            
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.value = media.urn
            labels.type = AnalyticsType.actionPlayMedia.rawValue
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.searchOpen.rawValue, labels: labels)
        case let .show(show):
            guard let navigationController = navigationController else { return }
            
            let showViewController = SectionViewController.showViewController(for: show)
            navigationController.pushViewController(showViewController, animated: true)
            
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.value = show.urn
            labels.type = AnalyticsType.actionDisplayShow.rawValue
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.searchTeaserOpen.rawValue, labels: labels)
            
            SRGDataProvider.current!.increaseSearchResultsViewCount(for: show)
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
        case .loading:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        
        switch item {
        case let .media(media):
            return ContextMenu.configuration(for: media, at: indexPath, in: self)
        case let .show(show):
            return ContextMenu.configuration(for: show, at: indexPath, in: self)
        case .loading:
            return nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        ContextMenu.commitPreview(in: self, animator: animator)
    }
    
    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return preview(for: configuration, in: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return preview(for: configuration, in: collectionView)
    }
    
    private func preview(for configuration: UIContextMenuConfiguration, in collectionView: UICollectionView) -> UITargetedPreview? {
        guard let interactionView = ContextMenu.interactionView(in: collectionView, with: configuration) else { return nil }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = view.backgroundColor
        return UITargetedPreview(view: interactionView, parameters: parameters)
    }
#endif
    
#if os(tvOS)
    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return false
    }
#endif
}

#if os(iOS)
// Replace search icon with a back button
// See https://betterprogramming.pub/how-to-change-the-search-icon-in-a-uisearchbar-150b775fb6c8
extension SearchViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        guard let searchBar = searchBar as? SearchBar, let textField = searchBar.textField else { return }
        defaultLeftView = textField.leftView
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "arrow.left.circle.fill"), for: .normal)
        button.addTarget(self, action: #selector(closeKeyboard(_:)), for: .touchUpInside)
        button.tintColor = .secondaryLabel
        button.accessibilityLabel = NSLocalizedString("Dismiss keyboard", comment: "Label of the search bar button to close the keyboard")
        textField.leftView = button
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let searchBar = searchBar as? SearchBar, let textField = searchBar.textField else { return }
        textField.leftView = defaultLeftView
    }
}
#endif

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
#if os(iOS)
        guard !searchUpdateInhibited else { return }
#endif
        model.query = searchController.searchBar.text ?? ""
    }
}

extension SearchViewController: UIScrollViewDelegate {
#if os(iOS)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Avoid the collection jumping when pulling to refresh. Only mark the refresh as being triggered.
        if refreshTriggered {
            model.reload(deep: true)
            refreshTriggered = false
        }
    }
    
    // The system default behavior does not lead to correct results when large titles are displayed. Override.
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollView.play_scrollToTop(animated: true)
        return false
    }
#endif
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
#if os(iOS)
        if scrollView.isDragging && !scrollView.isDecelerating {
            searchController?.searchBar.resignFirstResponder()
        }
        
        // TODO: This is a workaround for UIKit bugs when using a search controller with `hidesSearchBarWhenScrolling`
        //       and large navigation titles:
        //         - After entering input with the search bar expanded, scrolling down does not reveal any title in
        //           the collapsed navigation bar.
        //         - After entering input with the search bar collapsed, scrolling to the top does not reveal any large
        //           title in the expanded navigation bar.
        //       The titles are in fact there but their opacity is incorrect. To fix this bug we re-attach the same search
        //       controller we use to the navigation item during scrolling, forcing title updates. We first must set the
        //       navigation item search controller to `nil` so that a refresh is triggered, which clears the search
        //       bar text, an update we need to inhibit. We then restore the search criterium, which does not trigger
        //       any further view model reload since duplicate query updates are inhibited. This is a bit expensive so
        //       this should only be done when the collection view is at the top.
        //
        //       This bug will be reported to Apple and this workaround will hopefully be removed in the future.
        let yContentOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let yOffsetDifference = yContentOffset - previousYContentOffset
        
        if let navigationBar = navigationController?.navigationBar, navigationBar.prefersLargeTitles,
           previousYContentOffset > 0, yOffsetDifference < 0 {
            let searchController = navigationItem.searchController
            searchUpdateInhibited = true
            navigationItem.searchController = nil
            navigationItem.searchController = searchController
            searchUpdateInhibited = false
            searchController?.searchBar.text = model.query
        }
        
        previousYContentOffset = yContentOffset
        // End of workaround
#endif
        
        if scrollView.contentSize.height > 0 {
            let numberOfScreens = 4
            if scrollView.contentOffset.y > scrollView.contentSize.height - CGFloat(numberOfScreens) * scrollView.frame.height {
                model.loadMore()
            }
        }
    }
}

// MARK: Layout

private extension SearchViewController {
    private static let emptyViewInsets = EdgeInsets(top: constant(iOS: 0, tvOS: 350), leading: 0, bottom: 0, trailing: 0)
    private static let layoutVerticalMargin: CGFloat = constant(iOS: 8, tvOS: 0)
    
    private func layoutConfiguration() -> UICollectionViewCompositionalLayoutConfiguration {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = constant(iOS: 35, tvOS: 70)
        configuration.contentInsetsReference = constant(iOS: .automatic, tvOS: .layoutMargins)
        return configuration
    }
    
    private func layout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, layoutEnvironment in
            guard let self = self else { return nil }
            let layoutWidth = layoutEnvironment.container.effectiveContentSize.width
            
            func sectionSupplementaryItems(for section: SearchViewModel.Section) -> [NSCollectionLayoutBoundarySupplementaryItem] {
                let headerSize = SectionHeaderView.size(section: section, settings: self.model.settings, layoutWidth: layoutWidth)
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                return [header]
            }
            
            func layoutSection(for section: SearchViewModel.Section, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
                let horizontalSizeClass = layoutEnvironment.traitCollection.horizontalSizeClass
                
                switch section {
                case .medias:
                    if horizontalSizeClass == .compact {
                        return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, spacing: Self.itemSpacing) { _, _ in
                            return MediaCellSize.fullWidth()
                        }
                    }
                    else {
                        return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing) { layoutWidth, spacing in
                            return MediaCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                        }
                    }
                case .shows:
                    let layoutSection = NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, spacing: Self.itemSpacing) { _, _ in
                        return ShowCellSize.swimlane(for: .default)
                    }
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .mostSearchedShows:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing) { layoutWidth, spacing in
                        return ShowCellSize.grid(for: .default, layoutWidth: layoutWidth, spacing: spacing)
                    }
                case .loading:
                    return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth) { _, _ in
                        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(150))
                    }
                }
            }
            
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[sectionIndex]
            
            let layoutSection = layoutSection(for: section, layoutEnvironment: layoutEnvironment)
            layoutSection.boundarySupplementaryItems = sectionSupplementaryItems(for: section)
            return layoutSection
        }, configuration: layoutConfiguration())
    }
}

// MARK: Cells

private extension SearchViewController {
    struct ItemCell: View {
        let item: SearchViewModel.Item
        
        var body: some View {
            switch item {
            case let .media(media):
                MediaCell(media: media, style: .show)
            case let .show(show):
                ShowCell(show: show, style: .standard, imageVariant: .default)
            case .loading:
                ActivityIndicator()
            }
        }
    }
}

// MARK: Headers

private extension SearchViewController {
    struct SectionHeaderView: View {
        let section: SearchViewModel.Section
        let settings: SRGMediaSearchSettings
        
        private static func title(for section: SearchViewModel.Section, settings: SRGMediaSearchSettings) -> String? {
            switch section {
            case .medias:
                guard !ApplicationConfiguration.shared.radioChannels.isEmpty else { return nil }
                switch settings.mediaType {
                case .video:
                    return NSLocalizedString("Videos", comment: "Header for video search results")
                case .audio:
                    return NSLocalizedString("Audios", comment: "Header for audio search results")
                case .none:
                    return NSLocalizedString("Videos and audios", comment: "Header for video and audio search results")
                }
            case .shows:
                return NSLocalizedString("Shows", comment: "Show search result header")
            case .mostSearchedShows:
                return NSLocalizedString("Most searched shows", comment: "Most searched shows header")
            case .loading:
                return nil
            }
        }
        
        var body: some View {
            if let title = Self.title(for: section, settings: settings) {
                HeaderView(title: title, subtitle: nil, hasDetailDisclosure: false)
            }
            else {
                Color.clear
            }
        }
        
        static func size(section: SearchViewModel.Section, settings: SRGMediaSearchSettings, layoutWidth: CGFloat) -> NSCollectionLayoutSize {
            return HeaderViewSize.recommended(forTitle: title(for: section, settings: settings), subtitle: nil, layoutWidth: layoutWidth)
        }
    }
}
