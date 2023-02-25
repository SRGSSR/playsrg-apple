//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import Intents
import SRGAppearanceSwift
import SwiftUI
import UIKit

// MARK: View controller

final class SectionViewController: UIViewController {
    let model: SectionViewModel
    var initialSectionId: String?
    let fromPushNotification: Bool
    
    private static let itemSpacing: CGFloat = constant(iOS: 8, tvOS: 40)
    private static let margin = constant(iOS: 2 * itemSpacing, tvOS: 0)
    
    private var cancellables = Set<AnyCancellable>()
    
    private var dataSource: UICollectionViewDiffableDataSource<SectionViewModel.Section, SectionViewModel.Item>!
    
    private weak var collectionView: UICollectionView!
    private weak var emptyContentView: HostView<EmptyContentView>!
    
#if os(iOS)
    private weak var refreshControl: UIRefreshControl!
    
    private var refreshTriggered = false
    private var firstHeaderVisible = true
#endif
    
    private var contentInsets: UIEdgeInsets
    private var leftBarButtonItem: UIBarButtonItem?
    
    private var globalHeaderTitle: String? {
#if os(tvOS)
        return (tabBarController == nil && model.displaysTitle) ? model.title : nil
#else
        return nil
#endif
    }
    
    private static func snapshot(from state: SectionViewModel.State) -> NSDiffableDataSourceSnapshot<SectionViewModel.Section, SectionViewModel.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<SectionViewModel.Section, SectionViewModel.Item>()
        if case let .loaded(rows: rows) = state {
            for row in rows {
                snapshot.appendSections([row.section])
                snapshot.appendItems(row.items, toSection: row.section)
            }
        }
        return snapshot
    }
    
    /**
     *  Use `initialSectionId` to provide the collection view section id where the view should initially open. If not found or
     *  specified the view opens at its top.
     */
    init(section: Content.Section, filter: SectionFiltering? = nil, initialSectionId: String? = nil, fromPushNotification: Bool = false) {
        model = SectionViewModel(section: section, filter: filter)
        self.initialSectionId = initialSectionId
        self.fromPushNotification = fromPushNotification
        contentInsets = Self.contentInsets(for: model.state)
        super.init(nibName: nil, bundle: nil)
        title = model.displaysTitle ? model.title : nil
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
        collectionView.allowsMultipleSelectionDuringEditing = true
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let emptyContentView = HostView<EmptyContentView>(frame: .zero)
        collectionView.backgroundView = emptyContentView
        self.emptyContentView = emptyContentView
        
#if os(tvOS)
        tabBarObservedScrollView = collectionView
#else
        let refreshControl = RefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.insertSubview(refreshControl, at: 0)
        self.refreshControl = refreshControl
#endif
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
#if os(iOS)
        navigationItem.largeTitleDisplayMode = model.configuration.viewModelProperties.largeTitleDisplayMode
        updateNavigationBar()
#endif
        
        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<ItemCell>, SectionViewModel.Item> { [weak self] cell, _, item in
            guard let self else { return }
            cell.content = ItemCell(item: item, configuration: self.model.configuration)
        }
        
        dataSource = IndexedCollectionViewDiffableDataSource(collectionView: collectionView, minimumIndexTitlesCount: 4) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        let globalHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<TitleView>>(elementKind: Header.global.rawValue) { [weak self] view, _, _ in
            guard let self else { return }
            view.content = TitleView(text: self.globalHeaderTitle)
            if let hostController = view.hostController {
                self.addChild(hostController)
            }
        }
        
        let sectionHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<SectionHeaderView>>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] view, _, indexPath in
            guard let self else { return }
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            view.content = SectionHeaderView(section: section, configuration: self.model.configuration)
            if let hostController = view.hostController {
                self.addChild(hostController)
            }
        }
        
        let sectionFooterViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<SectionFooterView>>(elementKind: UICollectionView.elementKindSectionFooter) { [weak self] view, _, indexPath in
            guard let self else { return }
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            view.content = SectionFooterView(section: section)
            if let hostController = view.hostController {
                self.addChild(hostController)
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            switch kind {
            case Header.global.rawValue:
                return collectionView.dequeueConfiguredReusableSupplementary(using: globalHeaderViewRegistration, for: indexPath)
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(using: sectionHeaderViewRegistration, for: indexPath)
            case UICollectionView.elementKindSectionFooter:
                return collectionView.dequeueConfiguredReusableSupplementary(using: sectionFooterViewRegistration, for: indexPath)
            default:
                return nil
            }
        }
        
        model.$state
            .sink { [weak self] state in
                self?.reloadData(for: state)
            }
            .store(in: &cancellables)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.reload()
        deselectItems(in: collectionView, animated: animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        userActivity = model.configuration.viewModelProperties.userActivity
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        userActivity = nil
    }
    
#if os(iOS)
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        collectionView.isEditing = editing
        
        if isEditing {
            leftBarButtonItem = navigationItem.leftBarButtonItem
        }
        else {
            leftBarButtonItem = nil
            model.clearSelection()
        }
        
        // Force a cell global appearance update
        collectionView.reloadData()
        
        updateNavigationBar()
    }
    
    private func updateNavigationBar(for state: SectionViewModel.State) {
        if model.configuration.properties.supportsEdition && state.hasContent {
            navigationItem.rightBarButtonItem = editButtonItem
            
            if isEditing {
                navigationItem.title = Self.title(for: model.numberOfSelectedItems)
                editButtonItem.title = NSLocalizedString("Done", comment: "Done button title")
                
                let numberOfSelectedItems = model.numberOfSelectedItems
                let deleteBarButtonItem = UIBarButtonItem(image: UIImage(named: "delete"), style: .plain, target: self, action: #selector(deleteSelectedItems))
                deleteBarButtonItem.tintColor = .red
                deleteBarButtonItem.isEnabled = (numberOfSelectedItems != 0)
                deleteBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Delete", comment: "Delete button label")
                deleteBarButtonItem.accessibilityValue = (numberOfSelectedItems != 0) ? Self.title(for: numberOfSelectedItems) : nil
                navigationItem.leftBarButtonItem = deleteBarButtonItem
            }
            else {
                navigationItem.title = (model.displaysTitle || !firstHeaderVisible) ? model.title : nil
                editButtonItem.title = NSLocalizedString("Select", comment: "Select button title")
                navigationItem.leftBarButtonItem = leftBarButtonItem
            }
        }
        else {
            navigationItem.title = (model.displaysTitle || !firstHeaderVisible) ? model.title : nil
            
            if model.configuration.properties.sharingItem != nil {
                let shareButtonItem = UIBarButtonItem(image: UIImage(named: "share"),
                                                      style: .plain,
                                                      target: self,
                                                      action: #selector(self.shareContent(_:)))
                shareButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Share", comment: "Share button label on player view")
                navigationItem.rightBarButtonItem = shareButtonItem
            }
            else {
                navigationItem.rightBarButtonItem = nil
            }
            
            navigationItem.leftBarButtonItem = leftBarButtonItem
        }
    }
    
    private func updateNavigationBar() {
        updateNavigationBar(for: model.state)
    }
    
    private static func title(for numberOfSelectedItems: Int) -> String {
        // TODO: Should use plural localization here but a bit costly (and not sure it is well integrated with CrowdIn)
        //       See https://developer.apple.com/documentation/xcode/localizing-strings-that-contain-plurals
        switch numberOfSelectedItems {
        case 0:
            return NSLocalizedString("Select items", comment: "Title displayed when no item has been selected")
        case 1:
            return NSLocalizedString("1 item", comment: "Title displayed when 1 item has been selected")
        default:
            return String(format: NSLocalizedString("%d items", comment: "Title displayed when several items have been selected"), numberOfSelectedItems)
        }
    }
#endif
    
    private func reloadData(for state: SectionViewModel.State) {
        switch state {
        case .loading:
            emptyContentView.content = EmptyContentView(state: .loading)
        case let .failed(error: error):
            emptyContentView.content = EmptyContentView(state: .failed(error: error))
        case .loaded:
            let properties = model.configuration.properties
            emptyContentView.content = state.displaysEmptyContentView ? EmptyContentView(state: .empty(type: properties.emptyType)) : nil
        }
        
#if os(iOS)
        updateNavigationBar(for: state)
#endif
        
        contentInsets = Self.contentInsets(for: state)
        play_setNeedsContentInsetsUpdate()
        
        DispatchQueue.global(qos: .userInteractive).async {
            // Can be triggered on a background thread. Layout is updated on the main thread.
            self.dataSource.apply(Self.snapshot(from: state)) {
#if os(iOS)
                self.collectionView.reloadSectionIndexBar()
                
                // Apply colors when the section bar might be visible.
                self.collectionView.setSectionBarAppearance(indexColor: .srgGray96,
                                                            indexBackgroundColor: .init(white: 0, alpha: 0.3))
                self.scrollToInitialSection()
                
                // Avoid stopping scrolling.
                // See http://stackoverflow.com/a/31681037/760435
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
#endif
            }
        }
    }
    
    private func scrollToInitialSection() {
        guard initialSectionId != nil else { return }
        
        let sectionIdentifiers = dataSource.snapshot().sectionIdentifiers
        guard !sectionIdentifiers.isEmpty else { return }
        
        if let index = sectionIdentifiers.firstIndex(where: { $0.id == initialSectionId }) {
            collectionView.play_scrollToItem(at: IndexPath(row: 0, section: index), at: .top, animated: true)
        }
        initialSectionId = nil
    }
    
    private static func contentInsets(for state: SectionViewModel.State) -> UIEdgeInsets {
        let top = (state.headerSize == .zero) ? Self.layoutVerticalMargin : 0
        return UIEdgeInsets(top: top, left: 0, bottom: Self.layoutVerticalMargin, right: 0)
    }
    
#if os(iOS)
    @objc private func pullToRefresh(_ refreshControl: RefreshControl) {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        refreshTriggered = true
    }
    
    @objc private func shareContent(_ barButtonItem: UIBarButtonItem) {
        guard let sharingItem = model.configuration.properties.sharingItem else { return }
        
        let activityViewController = UIActivityViewController(sharingItem: sharingItem, from: .button)
        activityViewController.modalPresentationStyle = .popover
        
        let popoverPresentationController = activityViewController.popoverPresentationController
        popoverPresentationController?.barButtonItem = barButtonItem
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc private func deleteSelectedItems(_ barButtonItem: UIBarButtonItem) {
        let alertController = UIAlertController(title: NSLocalizedString("Delete", comment: "Title of the confirmation pop-up displayed when the user is about to delete items"),
                                                message: NSLocalizedString("The selected items will be deleted.", comment: "Confirmation message displayed when the user is about to delete selected entries"),
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Title of a cancel button"), style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Title of a delete button"), style: .destructive, handler: { _ in
            self.model.deleteSelection()
            self.setEditing(false, animated: true)
        }))
        present(alertController, animated: true, completion: nil)
    }
#endif
}

// MARK: Types

private extension SectionViewController {
    enum Header: String {
        case global
    }
}

// MARK: Objective-C API

@objc protocol DailyMediasViewController {
    var date: Date? { get }
    var scrollView: UIScrollView { get }
}

extension SectionViewController: DailyMediasViewController {
    var date: Date? {
        guard case let .configured(section) = model.configuration.wrappedValue else { return nil }
        switch section {
        case let .tvEpisodesForDay(day), let .radioEpisodesForDay(day, channelUid: _):
            return day.date
        default:
            return nil
        }
    }
    
    var scrollView: UIScrollView {
        return collectionView
    }
}

extension SectionViewController {
    @objc static func viewController(forContentSection contentSection: SRGContentSection) -> SectionViewController {
        return SectionViewController(section: .content(contentSection))
    }
    
#if os(iOS)
    @objc static func downloadsViewController() -> SectionViewController {
        return SectionViewController(section: .configured(.downloads))
    }
    
    @objc static func notificationsViewController() -> SectionViewController {
        return SectionViewController(section: .configured(.notifications))
    }
#endif
    
    @objc static func favoriteShowsViewController() -> SectionViewController {
        return SectionViewController(section: .configured(.favoriteShows))
    }
    
    @objc static func historyViewController() -> SectionViewController {
        return SectionViewController(section: .configured(.history))
    }
    
    @objc static func watchLaterViewController() -> SectionViewController {
        return SectionViewController(section: .configured(.watchLater))
    }
    
    @objc static func mediasViewController(forDay day: SRGDay, channelUid: String?) -> SectionViewController & DailyMediasViewController {
        if let channelUid {
            return SectionViewController(section: .configured(.radioEpisodesForDay(day, channelUid: channelUid)))
        }
        else {
            return SectionViewController(section: .configured(.tvEpisodesForDay(day)))
        }
    }
    
    @objc static func showsViewController(forChannelUid channelUid: String?, initialSectionId: String?) -> SectionViewController {
        if let channelUid {
            return SectionViewController(section: .configured(.radioAllShows(channelUid: channelUid)), initialSectionId: initialSectionId)
        }
        else {
            return SectionViewController(section: .configured(.tvAllShows), initialSectionId: initialSectionId)
        }
    }
    
    @objc static func showsViewController(forChannelUid channelUid: String?) -> SectionViewController {
        return showsViewController(forChannelUid: channelUid, initialSectionId: nil)
    }
    
    @objc static func showViewController(for show: SRGShow, fromPushNotification: Bool) -> SectionViewController {
        return SectionViewController(section: .configured(.show(show)), fromPushNotification: fromPushNotification)
    }
    
    @objc static func showViewController(for show: SRGShow) -> SectionViewController {
        return showViewController(for: show, fromPushNotification: false)
    }
}

// MARK: Protocols

extension SectionViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        return collectionView != nil ? [collectionView] : nil
    }
    
    var play_paddingContentInsets: UIEdgeInsets {
        return contentInsets
    }
}

#if os(iOS)
extension SectionViewController: Oriented {
}
#endif

extension SectionViewController: ScrollableContent {
    var play_scrollableView: UIScrollView? {
        return collectionView
    }
}

extension SectionViewController: UICollectionViewDelegate {
#if os(iOS)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        
        if collectionView.isEditing {
            model.select(item)
            updateNavigationBar()
        }
        else {
            navigateToItem(item)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        
        model.deselect(item)
        updateNavigationBar()
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return model.configuration.properties.supportsEdition
    }
    
    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        if !isEditing {
            setEditing(true, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !collectionView.isEditing else { return nil }
        
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        return ContextMenu.configuration(for: item, at: indexPath, in: self)
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            if indexPath.section == 0 {
                firstHeaderVisible = true
                updateNavigationBar()
            }
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            if indexPath.section == 0 {
                firstHeaderVisible = false
                updateNavigationBar()
            }
        default:
            break
        }
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

extension SectionViewController: UIScrollViewDelegate {
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
        guard scrollView.contentSize.height > 0 else { return }
        
        let numberOfScreens = 4
        if scrollView.contentOffset.y > scrollView.contentSize.height - CGFloat(numberOfScreens) * scrollView.frame.height {
            model.loadMore()
        }
    }
}

extension SectionViewController: SRGAnalyticsViewTracking {
    var srg_pageViewTitle: String {
        return model.configuration.properties.analyticsTitle ?? ""
    }
    
    var srg_pageViewLevels: [String]? {
        return model.configuration.properties.analyticsLevels
    }
    
    var srg_isOpenedFromPushNotification: Bool {
        return fromPushNotification
    }
}

extension SectionViewController: SectionShowHeaderViewAction {
    func openShow(sender: Any?, event: OpenShowEvent?) {
        guard let event else { return }
        
#if os(tvOS)
        navigateToShow(event.show)
#else
        if let navigationController {
            let showViewController = SectionViewController.showViewController(for: event.show)
            navigationController.pushViewController(showViewController, animated: true)
        }
#endif
    }
}

#if os(iOS)
extension SectionViewController: TabBarActionable {
    func performActiveTabAction(animated: Bool) {
        collectionView?.play_scrollToTop(animated: animated)
    }
}
#endif

// MARK: Layout

private extension SectionViewController {
    private static let layoutVerticalMargin: CGFloat = constant(iOS: 8, tvOS: 0)
    
    private func layoutConfiguration() -> UICollectionViewCompositionalLayoutConfiguration {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = constant(iOS: .automatic, tvOS: .layoutMargins)
        configuration.interSectionSpacing = constant(iOS: 15, tvOS: 100)
        
        let headerSize = TitleViewSize.recommended(forText: globalHeaderTitle)
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: Header.global.rawValue, alignment: .topLeading)
        configuration.boundarySupplementaryItems = [header]
        
        return configuration
    }
    
    private func layout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, layoutEnvironment in
            func sectionSupplementaryItems(for section: SectionViewModel.Section, configuration: SectionViewModel.Configuration, layoutEnvironment: NSCollectionLayoutEnvironment) -> [NSCollectionLayoutBoundarySupplementaryItem] {
                let headerSize = SectionHeaderView.size(section: section,
                                                        configuration: configuration,
                                                        layoutWidth: layoutEnvironment.container.effectiveContentSize.width,
                                                        horizontalSizeClass: layoutEnvironment.traitCollection.horizontalSizeClass)
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                header.pinToVisibleBounds = configuration.viewModelProperties.pinHeadersToVisibleBounds
                
                let footerSize = SectionFooterView.size(section: section)
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
                
                return [header, footer]
            }
            
            func layoutSection(for section: SectionViewModel.Section, configuration: SectionViewModel.Configuration, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
                let layoutWidth = layoutEnvironment.container.effectiveContentSize.width
                let horizontalSizeClass = layoutEnvironment.traitCollection.horizontalSizeClass
                let top = section.header.sectionTopInset
                
                switch configuration.viewModelProperties.layout {
                case .mediaList:
#if os(iOS)
                    if horizontalSizeClass == .compact {
                        return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { _, _ in
                            return MediaCellSize.fullWidth()
                        }
                    }
                    else {
                        let spacing = (layoutWidth - LayoutMaxListWidth) / 4
                        return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, spacing: spacing, top: top) { layoutWidth, _ in
                            return MediaCellSize.largeList(layoutWidth: layoutWidth)
                        }
                    }
#else
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                        return MediaCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                    }
#endif
                case .mediaGrid:
                    if horizontalSizeClass == .compact {
                        return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { _, _ in
                            return MediaCellSize.fullWidth()
                        }
                    }
                    else {
                        return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                            return MediaCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                        }
                    }
                case .liveMediaGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                        return LiveMediaCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                    }
                case .showGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                        return ShowCellSize.grid(for: configuration.properties.imageVariant, layoutWidth: layoutWidth, spacing: spacing)
                    }
                case .topicGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                        return TopicCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                    }
#if os(iOS)
                case .downloadGrid:
                    if horizontalSizeClass == .compact {
                        return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { _, _ in
                            return DownloadCellSize.fullWidth()
                        }
                    }
                    else {
                        return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                            return DownloadCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                        }
                    }
                case .notificationList:
                    return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { _, _ in
                        return NotificationCellSize.fullWidth()
                    }
#endif
                }
            }
            
            guard let self else { return nil }
            
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[sectionIndex]
            let configuration = self.model.configuration
            
            let layoutSection = layoutSection(for: section, configuration: configuration, layoutEnvironment: layoutEnvironment)
            layoutSection.boundarySupplementaryItems = sectionSupplementaryItems(for: section, configuration: configuration, layoutEnvironment: layoutEnvironment)
            layoutSection.supplementariesFollowContentInsets = false
            return layoutSection
        }, configuration: layoutConfiguration())
    }
}

// MARK: Cells

private extension SectionViewController {
    struct ItemCell: View {
        let item: SectionViewModel.Item
        let configuration: SectionViewModel.Configuration
        
        var body: some View {
            switch item {
            case let .media(media):
                switch configuration.wrappedValue {
                case .content:
                    MediaCell(media: media, style: .show)
                case let .configured(configuredSection):
                    switch configuredSection {
                    case .show:
                        MediaCell(media: media, style: constant(iOS: .dateAndSummary, tvOS: .date), layout: constant(iOS: .horizontal, tvOS: .vertical))
                    case .radioEpisodesForDay, .tvEpisodesForDay:
                        MediaCell(media: media, style: .time)
                    default:
                        MediaCell(media: media, style: .show)
                    }
                }
            case let .show(show):
                let imageVariant = configuration.properties.imageVariant
                switch configuration.wrappedValue {
                case let .content(contentSection):
                    switch contentSection.type {
                    case .predefined:
                        switch contentSection.presentation.type {
                        case .favoriteShows:
                            ShowCell(show: show, style: .favorite, imageVariant: imageVariant)
                        default:
                            ShowCell(show: show, style: .standard, imageVariant: imageVariant)
                        }
                    default:
                        ShowCell(show: show, style: .standard, imageVariant: imageVariant)
                    }
                case let .configured(configuredSection):
                    switch configuredSection {
                    case .favoriteShows, .radioFavoriteShows:
                        ShowCell(show: show, style: .favorite, imageVariant: imageVariant)
                    default:
                        ShowCell(show: show, style: .standard, imageVariant: imageVariant)
                    }
                }
            case let .topic(topic):
                TopicCell(topic: topic)
#if os(iOS)
            case let .download(download):
                DownloadCell(download: download)
            case let .notification(notification):
                NotificationCell(notification: notification)
#endif
            case .transparent:
                Color.clear
            default:
                MediaCell(media: nil, style: .show)
            }
        }
    }
}

// MARK: Headers

private extension SectionViewController {
    struct SectionHeaderView: View {
        let section: SectionViewModel.Section
        let configuration: SectionViewModel.Configuration
        
        var body: some View {
            switch section.header {
            case let .title(title):
                TransluscentHeaderView(title: title, horizontalPadding: SectionViewController.margin)
            case let .item(item):
                switch item {
                case let .show(show):
                    SectionShowHeaderView(section: configuration.wrappedValue, show: show)
                default:
                    Color.clear
                }
            case let .show(show):
                ShowHeaderView(show: show)
            case .none:
                Color.clear
            }
        }
        
        static func size(section: SectionViewModel.Section, configuration: SectionViewModel.Configuration, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
            switch section.header {
            case let .title(title):
                return TransluscentHeaderViewSize.recommended(title: title, horizontalPadding: SectionViewController.margin, layoutWidth: layoutWidth)
            case let .item(item):
                switch item {
                case let .show(show):
                    return SectionShowHeaderViewSize.recommended(for: configuration.wrappedValue, show: show, layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
                default:
                    return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
                }
            case let .show(show):
                return ShowHeaderViewSize.recommended(for: show, layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
            case .none:
                return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
            }
        }
    }
}

// MARK: Footers

private extension SectionViewController {
    struct SectionFooterView: View {
        let section: SectionViewModel.Section
        
        var body: some View {
            switch section.footer {
#if os(iOS)
            case .diskInfo:
                DiskInfoFooterView()
#endif
            case .none:
                Color.clear
            }
        }
        
        static func size(section: SectionViewModel.Section) -> NSCollectionLayoutSize {
            switch section.footer {
#if os(iOS)
            case .diskInfo:
                return LayoutFullWidthCellSize(30)
#endif
            case .none:
                return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
            }
        }
    }
}

extension SectionViewController: ShowHeaderViewAction {
    func showMore(sender: Any?, event: ShowMoreEvent?) {
        guard let event else { return }
        
#if os(iOS)
        let sheetTextViewController = UIHostingController(rootView: SheetTextView(content: event.content))
        if #available(iOS 15.0, *) {
            if let sheet = sheetTextViewController.sheetPresentationController {
                sheet.detents = [.medium()]
            }
        }
        present(sheetTextViewController, animated: true, completion: nil)
#else
        navigateToText(event.content)
#endif
    }
}
