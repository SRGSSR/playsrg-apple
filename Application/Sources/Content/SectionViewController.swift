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
    private static let layoutHorizontalMargin: CGFloat = constant(iOS: 16, tvOS: 0)
    private static let layoutVerticalMargin: CGFloat = constant(iOS: 8, tvOS: 0)

    private var cancellables = Set<AnyCancellable>()

    private var dataSource: UICollectionViewDiffableDataSource<SectionViewModel.Section, SectionViewModel.Item>!

    private weak var collectionView: UICollectionView!
    private weak var emptyContentView: HostView<EmptyContentView>!

    #if os(iOS)
        private weak var refreshControl: UIRefreshControl!

        private var refreshTriggered = false
    #endif

    private var contentInsets: UIEdgeInsets
    private var leftBarButtonItem: UIBarButtonItem?

    private var headerTitle: String? {
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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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

        #if os(iOS)
            if #available(iOS 17.0, *) {
                collectionView.registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (collectionView: UICollectionView, _) in
                    collectionView.collectionViewLayout.invalidateLayout()
                }
            }
        #endif

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

        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<ItemCell>, SectionViewModel.Item> { [weak self] cell, indexPath, item in
            guard let self else { return }
            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            let isLastItem = indexPath.row + 1 == dataSource.snapshot().numberOfItems(inSection: section)
            cell.content = ItemCell(item: item, configuration: model.configuration, isLastItem: isLastItem)
            if let hostController = cell.hostController {
                addChild(hostController)
            }
        }

        dataSource = IndexedCollectionViewDiffableDataSource(collectionView: collectionView, minimumIndexTitlesCount: 4) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        let titleHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<TitleHeaderView>>(elementKind: Header.titleHeader.rawValue) { [weak self] view, _, _ in
            guard let self else { return }
            view.content = TitleHeaderView(headerTitle, titleTextAlignment: constant(iOS: .leading, tvOS: .center))
            if let hostController = view.hostController {
                addChild(hostController)
            }
        }

        let sectionHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<SectionHeaderView>>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] view, _, indexPath in
            guard let self else { return }
            let snapshot = dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            view.content = SectionHeaderView(section: section, configuration: model.configuration)
            if let hostController = view.hostController {
                addChild(hostController)
            }
        }

        let sectionFooterViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<SectionFooterView>>(elementKind: UICollectionView.elementKindSectionFooter) { [weak self] view, _, indexPath in
            guard let self else { return }
            let snapshot = dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            view.content = SectionFooterView(section: section)
            if let hostController = view.hostController {
                addChild(hostController)
            }
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            switch kind {
            case Header.titleHeader.rawValue:
                collectionView.dequeueConfiguredReusableSupplementary(using: titleHeaderViewRegistration, for: indexPath)
            case UICollectionView.elementKindSectionHeader:
                collectionView.dequeueConfiguredReusableSupplementary(using: sectionHeaderViewRegistration, for: indexPath)
            case UICollectionView.elementKindSectionFooter:
                collectionView.dequeueConfiguredReusableSupplementary(using: sectionFooterViewRegistration, for: indexPath)
            default:
                nil
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

        updateLayoutConfiguration()

        model.resetApplicationBadgeIfNeeded()
        model.reload()
        deselectItems(in: collectionView, animated: animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func updateLayoutConfiguration() {
        if let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewCompositionalLayout {
            collectionViewLayout.configuration = Self.layoutConfiguration(title: headerTitle, layoutWidth: view.safeAreaLayoutGuide.layoutFrame.width, horizontalSizeClass: view.traitCollection.horizontalSizeClass)
        }
    }

    #if os(iOS)
        override func setEditing(_ editing: Bool, animated: Bool) {
            super.setEditing(editing, animated: animated)

            collectionView.isEditing = editing

            if isEditing {
                leftBarButtonItem = navigationItem.leftBarButtonItem
            } else {
                leftBarButtonItem = nil
                model.clearSelection()
            }

            // Force a cell global appearance update
            collectionView.reloadData()

            updateNavigationBar()
        }

        private func updateNavigationBar(for state: SectionViewModel.State) {
            if model.configuration.properties.supportsEdition, state.hasContent {
                navigationItem.rightBarButtonItem = editButtonItem

                if isEditing {
                    navigationItem.title = Self.title(for: model.numberOfSelectedItems)
                    editButtonItem.title = NSLocalizedString("Done", comment: "Done button title")

                    let numberOfSelectedItems = model.numberOfSelectedItems
                    let deleteBarButtonItem = UIBarButtonItem(image: UIImage(resource: .delete), style: .plain, target: self, action: #selector(deleteSelectedItems))
                    deleteBarButtonItem.tintColor = .red
                    deleteBarButtonItem.isEnabled = (numberOfSelectedItems != 0)
                    deleteBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Delete", comment: "Delete button label")
                    deleteBarButtonItem.accessibilityValue = (numberOfSelectedItems != 0) ? Self.title(for: numberOfSelectedItems) : nil
                    navigationItem.leftBarButtonItem = deleteBarButtonItem
                } else {
                    navigationItem.title = model.displaysTitle ? model.title : nil
                    editButtonItem.title = NSLocalizedString("Select", comment: "Select button title")
                    navigationItem.leftBarButtonItem = leftBarButtonItem
                }
            } else {
                navigationItem.title = model.displaysTitle ? model.title : nil

                if model.configuration.properties.sharingItem != nil {
                    let shareButtonItem = UIBarButtonItem(image: UIImage(resource: .share),
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(shareContent(_:)))
                    shareButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Share", comment: "Share button label on section detail view")
                    navigationItem.rightBarButtonItem = shareButtonItem
                } else {
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
                NSLocalizedString("Select items", comment: "Title displayed when no item has been selected")
            case 1:
                NSLocalizedString("1 item", comment: "Title displayed when 1 item has been selected")
            default:
                String(format: NSLocalizedString("%d items", comment: "Title displayed when several items have been selected"), numberOfSelectedItems)
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
        let bottom = Self.layoutVerticalMargin
        return UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
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

            present(activityViewController, animated: true, completion: nil)
        }

        @objc private func deleteSelectedItems(_: UIBarButtonItem) {
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
        case titleHeader
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
        collectionView
    }
}

extension SectionViewController {
    @objc static func viewController(forContentSection contentSection: SRGContentSection, contentType: ContentType) -> SectionViewController {
        SectionViewController(section: .content(contentSection, type: contentType))
    }

    #if os(iOS)
        @objc static func downloadsViewController() -> SectionViewController {
            SectionViewController(section: .configured(.downloads))
        }

        @objc static func notificationsViewController() -> SectionViewController {
            SectionViewController(section: .configured(.notifications))
        }
    #endif

    @objc static func favoriteShowsViewController() -> SectionViewController {
        SectionViewController(section: .configured(.favoriteShows(contentType: .mixed)))
    }

    @objc static func historyViewController() -> SectionViewController {
        SectionViewController(section: .configured(.history))
    }

    @objc static func watchLaterViewController() -> SectionViewController {
        SectionViewController(section: .configured(.watchLater))
    }

    @objc static func mediasViewController(forDay day: SRGDay, transmission: SRGTransmission, channelUid: String?) -> SectionViewController & DailyMediasViewController {
        // FIXME: If `channelUid` is null, load all radio episodes by date, not only from the first radio channel uid.
        if transmission == .radio, let channelUid = channelUid ?? ApplicationConfiguration.shared.radioHomepageChannels.first?.uid {
            SectionViewController(section: .configured(.radioEpisodesForDay(day, channelUid: channelUid)))
        } else {
            SectionViewController(section: .configured(.tvEpisodesForDay(day)))
        }
    }

    static func showsViewController(for transmission: SRGTransmission, channelUid: String?, initialSectionId: String?) -> UIViewController {
        if transmission == .radio, let channelUid {
            SectionViewController(section: .configured(.radioAllShows(channelUid: channelUid)), initialSectionId: initialSectionId)
        } else if transmission == .radio {
            #if os(iOS)
                if ApplicationConfiguration.shared.radioHomepageChannels.count == 1 {
                    SectionViewController(section: .configured(.radioAllShows(channelUid: ApplicationConfiguration.shared.radioHomepageChannels[0].uid)), initialSectionId: nil)
                } else {
                    SectionViewController(section: .configured(.radioAllShowsAZ), initialSectionId: nil)
                }
            #else
                UIViewController()
            #endif
        } else {
            SectionViewController(section: .configured(.tvAllShows), initialSectionId: initialSectionId)
        }
    }

    static func showsViewController(for transmission: SRGTransmission, channelUid: String?) -> UIViewController {
        showsViewController(for: transmission, channelUid: channelUid, initialSectionId: nil)
    }
}

// MARK: Protocols

extension SectionViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        collectionView != nil ? [collectionView] : nil
    }

    var play_paddingContentInsets: UIEdgeInsets {
        contentInsets
    }
}

#if os(iOS)
    extension SectionViewController: Oriented {}
#endif

extension SectionViewController: ScrollableContent {
    var play_scrollableView: UIScrollView? {
        collectionView
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
            } else {
                navigateToItem(item)
            }
        }

        func collectionView(_: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
            let snapshot = dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]

            model.deselect(item)
            updateNavigationBar()
        }

        func collectionView(_: UICollectionView, shouldBeginMultipleSelectionInteractionAt _: IndexPath) -> Bool {
            model.configuration.properties.supportsEdition
        }

        func collectionView(_: UICollectionView, didBeginMultipleSelectionInteractionAt _: IndexPath) {
            if !isEditing {
                setEditing(true, animated: true)
            }
        }

        func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
            guard !collectionView.isEditing else { return nil }

            let snapshot = dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
            return ContextMenu.configuration(for: item, at: indexPath, in: self)
        }

        func collectionView(_: UICollectionView, willPerformPreviewActionForMenuWith _: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
            ContextMenu.commitPreview(in: self, animator: animator)
        }

        func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
            preview(for: configuration, in: collectionView)
        }

        func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
            preview(for: configuration, in: collectionView)
        }

        private func preview(for configuration: UIContextMenuConfiguration, in collectionView: UICollectionView) -> UITargetedPreview? {
            guard let interactionView = ContextMenu.interactionView(in: collectionView, with: configuration) else { return nil }
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = view.backgroundColor
            return UITargetedPreview(view: interactionView, parameters: parameters)
        }
    #endif

    #if os(tvOS)
        func collectionView(_: UICollectionView, canFocusItemAt _: IndexPath) -> Bool {
            false
        }
    #endif
}

extension SectionViewController: UIScrollViewDelegate {
    #if os(iOS)
        func scrollViewDidEndDecelerating(_: UIScrollView) {
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
        model.configuration.properties.analyticsTitle ?? ""
    }

    var srg_pageViewType: String {
        model.configuration.properties.analyticsType ?? ""
    }

    var srg_pageViewLevels: [String]? {
        model.configuration.properties.analyticsLevels
    }

    var srg_isOpenedFromPushNotification: Bool {
        fromPushNotification
    }
}

extension SectionViewController: SectionShowHeaderViewAction {
    func openShow(sender _: Any?, event: OpenShowEvent?) {
        guard let event else { return }

        #if os(tvOS)
            navigateToShow(event.show)
        #else
            if let navigationController {
                let pageViewController = PageViewController(id: .show(event.show))
                navigationController.pushViewController(pageViewController, animated: true)
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
    private static func layoutConfiguration(title: String?, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> UICollectionViewCompositionalLayoutConfiguration {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = constant(iOS: .automatic, tvOS: .layoutMargins)
        configuration.interSectionSpacing = constant(iOS: 15, tvOS: 100)

        let titleHeaderSize = TitleHeaderViewSize.recommended(for: title, layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
        configuration.boundarySupplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem(layoutSize: titleHeaderSize, elementKind: Header.titleHeader.rawValue, alignment: .topLeading)]

        return configuration
    }

    private func layout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, layoutEnvironment in
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
                        let horizontalMargin = horizontalSizeClass == .compact ? Self.layoutHorizontalMargin : Self.layoutHorizontalMargin * 2
                        return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin, spacing: Self.itemSpacing, top: top) { _, _ in
                            switch configuration.properties.mediaType {
                            case .audio:
                                if ApplicationConfiguration.shared.arePodcastImagesEnabled {
                                    SmallMediaSquareCellSize.fullWidth()
                                } else {
                                    MediaCellSize.fullWidth()
                                }
                            default:
                                MediaCellSize.fullWidth()
                            }
                        }
                    #else
                        return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, horizontalMargin: Self.layoutHorizontalMargin, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                            MediaCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                        }
                    #endif
                case .mediaGrid:
                    if horizontalSizeClass == .compact {
                        return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: Self.layoutHorizontalMargin, spacing: Self.itemSpacing, top: top) { _, _ in
                            switch configuration.properties.mediaType {
                            case .audio:
                                if ApplicationConfiguration.shared.arePodcastImagesEnabled {
                                    SmallMediaSquareCellSize.fullWidth()
                                } else {
                                    MediaCellSize.fullWidth(horizontalSizeClass: horizontalSizeClass)
                                }
                            default:
                                MediaCellSize.fullWidth(horizontalSizeClass: horizontalSizeClass)
                            }
                        }
                    } else {
                        return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, horizontalMargin: Self.layoutHorizontalMargin, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                            MediaCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                        }
                    }
                case .liveMediaGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, horizontalMargin: Self.layoutHorizontalMargin, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                        LiveMediaCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                    }
                case .showGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, horizontalMargin: Self.layoutHorizontalMargin, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                        ShowCellSize.grid(for: configuration.properties.imageVariant, layoutWidth: layoutWidth, spacing: spacing)
                    }
                case .topicGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, horizontalMargin: Self.layoutHorizontalMargin, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                        TopicCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                    }
                #if os(iOS)
                    case .downloadGrid:
                        if horizontalSizeClass == .compact {
                            return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, spacing: Self.itemSpacing, top: top) { _, _ in
                                DownloadCellSize.fullWidth()
                            }
                        } else {
                            return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, horizontalMargin: Self.layoutHorizontalMargin, spacing: Self.itemSpacing, top: top) { layoutWidth, spacing in
                                DownloadCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                            }
                        }
                    case .notificationList:
                        return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: Self.layoutHorizontalMargin, spacing: Self.itemSpacing, top: top) { _, _ in
                            NotificationCellSize.fullWidth()
                        }
                #endif
                }
            }

            guard let self else { return nil }

            let snapshot = dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[sectionIndex]
            let configuration = model.configuration

            let layoutSection = layoutSection(for: section, configuration: configuration, layoutEnvironment: layoutEnvironment)
            layoutSection.boundarySupplementaryItems = sectionSupplementaryItems(for: section, configuration: configuration, layoutEnvironment: layoutEnvironment)
            layoutSection.supplementariesFollowContentInsets = false
            return layoutSection
        }, configuration: Self.layoutConfiguration(title: headerTitle, layoutWidth: 0, horizontalSizeClass: .unspecified))
    }
}

// MARK: Cells

private extension SectionViewController {
    struct ItemCell: View {
        let item: SectionViewModel.Item
        let configuration: SectionViewModel.Configuration
        let isLastItem: Bool

        var body: some View {
            switch item {
            case let .media(media):
                switch configuration.wrappedValue {
                case let .content(contentSection, _, _):
                    switch contentSection.type {
                    case .predefined:
                        switch contentSection.presentation.type {
                        case .availableEpisodes:
                            if configuration.viewModelProperties.layout == .mediaList {
                                MediaCell(media: media, style: .dateAndSummary, layout: .horizontal)
                            } else {
                                MediaCell(media: media, style: .date)
                            }
                        default:
                            MediaCell(media: media, style: .show)
                        }
                    default:
                        MediaCell(media: media, style: .show)
                    }
                case let .configured(configuredSection):
                    switch configuredSection {
                    case .availableEpisodes:
                        if configuration.viewModelProperties.layout == .mediaList {
                            MediaCell(media: media, style: .dateAndSummary, layout: .horizontal)
                        } else {
                            MediaCell(media: media, style: .date)
                        }
                    case .radioEpisodesForDay, .tvEpisodesForDay:
                        MediaCell(media: media, style: .time)
                    case .history, .watchLater:
                        MediaCell(media: media, style: .show, forceDefaultAspectRatio: true)
                    default:
                        MediaCell(media: media, style: .show)
                    }
                }
            case let .show(show):
                let imageVariant = configuration.properties.imageVariant
                switch configuration.wrappedValue {
                case let .content(contentSection, _, _):
                    switch contentSection.type {
                    case .predefined:
                        switch contentSection.presentation.type {
                        case .favoriteShows:
                            ShowCell(show: show, style: .favorite, imageVariant: imageVariant, isSwimlaneLayout: false)
                        default:
                            ShowCell(show: show, style: .standard, imageVariant: imageVariant, isSwimlaneLayout: false)
                        }
                    default:
                        ShowCell(show: show, style: .standard, imageVariant: imageVariant, isSwimlaneLayout: false)
                    }
                case let .configured(configuredSection):
                    switch configuredSection {
                    case .favoriteShows, .radioFavoriteShows:
                        ShowCell(show: show, style: .favorite, imageVariant: imageVariant, isSwimlaneLayout: false)
                    default:
                        ShowCell(show: show, style: .standard, imageVariant: imageVariant, isSwimlaneLayout: false)
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
                TransluscentHeaderView(title: title, horizontalPadding: SectionViewController.layoutHorizontalMargin)
            case let .item(item):
                switch item {
                case let .show(show):
                    SectionShowHeaderView(section: configuration.wrappedValue, show: show)
                default:
                    Color.clear
                }
            case .none:
                Color.clear
            }
        }

        static func size(section: SectionViewModel.Section, configuration: SectionViewModel.Configuration, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
            switch section.header {
            case let .title(title):
                TransluscentHeaderViewSize.recommended(title: title, horizontalPadding: SectionViewController.layoutHorizontalMargin, layoutWidth: layoutWidth)
            case let .item(item):
                switch item {
                case let .show(show):
                    SectionShowHeaderViewSize.recommended(for: configuration.wrappedValue, show: show, layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
                default:
                    NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
                }
            case .none:
                NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
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
    func showMore(sender _: Any?, event: ShowMoreEvent?) {
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
