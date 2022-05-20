//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAppearanceSwift
import SRGDataProviderModel
import SwiftUI
import UIKit

// MARK: Protocols

#if os(iOS)
protocol SearchResultsViewControllerDelegate: AnyObject {
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didSelectItem item: SearchViewModel.Item)
}
#endif

// MARK: View controller

final class SearchResultsViewController: UIViewController {
    @ObservedObject private var model: SearchViewModel
    private weak var searchViewController: SearchViewController?
    
#if os(iOS)
    weak var delegate: SearchResultsViewControllerDelegate?
#endif
    
    private var cancellables = Set<AnyCancellable>()
    
    private var dataSource: UICollectionViewDiffableDataSource<SearchViewModel.Section, SearchViewModel.Item>!
    
    private weak var collectionView: UICollectionView!
    private weak var emptyView: HostView<EmptyView>!
    
#if os(iOS)
    private weak var refreshControl: UIRefreshControl!
    
    private var refreshTriggered = false
#endif
    
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
    
    init(model: SearchViewModel, searchViewController: SearchViewController) {
        self.model = model
        self.searchViewController = searchViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .clear
        
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
                self?.reloadData(for: state)
            }
            .store(in: &cancellables)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if os(iOS)
        deselectItems(in: collectionView, animated: animated)
#endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if os(tvOS)
        if let searchController = parent as? UISearchController {
            searchController.searchControllerObservedScrollView = collectionView
        }
        
        searchViewController?.tabBarObservedScrollView = collectionView
#endif
    }
    
#if os(iOS)
    func scrollToTop(animated: Bool) {
        collectionView.play_scrollToTop(animated: animated)
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

// MARK: Protocols

extension SearchResultsViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        return collectionView != nil ? [collectionView] : nil
    }
    
    var play_paddingContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: Self.layoutVerticalMargin, left: 0, bottom: Self.layoutVerticalMargin, right: 0)
    }
    
    var play_contentParentViewController: UIViewController? {
        return searchViewController
    }
}

extension SearchResultsViewController: UICollectionViewDelegate {
#if os(iOS)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        delegate?.searchResultsViewController(self, didSelectItem: item)
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
        guard let searchViewController = searchViewController else { return }
        ContextMenu.commitPreview(in: searchViewController, animator: animator)
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

extension SearchResultsViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
#if os(iOS)
        // Avoid the collection jumping when pulling to refresh. Only mark the refresh as being triggered.
        if refreshTriggered {
            model.reload(deep: true)
            refreshTriggered = false
        }
#endif
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
#if os(iOS)
        if scrollView.isDragging && !scrollView.isDecelerating {
            if let searchController = parent as? UISearchController {
                searchController.searchBar.resignFirstResponder()
            }
        }
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

private extension SearchResultsViewController {
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

private extension SearchResultsViewController {
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

private extension SearchResultsViewController {
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
            return HeaderViewSize.recommended(title: title(for: section, settings: settings), subtitle: nil, layoutWidth: layoutWidth)
        }
    }
}
