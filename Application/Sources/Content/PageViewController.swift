//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAppearanceSwift
import SwiftUI
import UIKit

#if os(iOS)
import GoogleCast
#endif

// MARK: View controller

final class PageViewController: UIViewController {
    private let model: PageViewModel
    private let fromPushNotification: Bool
    
    private var cancellables = Set<AnyCancellable>()
    
    private var dataSource: UICollectionViewDiffableDataSource<PageViewModel.Section, PageViewModel.Item>!
    
    private weak var collectionView: UICollectionView!
    private weak var emptyContentView: HostView<EmptyContentView>!
    
#if os(iOS)
    private weak var refreshControl: UIRefreshControl!
    private weak var googleCastButton: GoogleCastFloatingButton?
    
    private var isNavigationBarHidden: Bool {
        return model.id.isNavigationBarHidden && !UIAccessibility.isVoiceOverRunning
    }
    
    private var refreshTriggered = false
    private var headerWithTitleVisible = false
#endif
    
    private var analyticsPageViewTracked = false
    
    private static func snapshot(from state: PageViewModel.State) -> NSDiffableDataSourceSnapshot<PageViewModel.Section, PageViewModel.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<PageViewModel.Section, PageViewModel.Item>()
        if case let .loaded(rows: rows, _) = state {
            for row in rows {
                snapshot.appendSections([row.section])
                snapshot.appendItems(row.items, toSection: row.section)
            }
        }
        return snapshot
    }
    
#if os(iOS)
    private static func showByDateViewController(radioChannel: RadioChannel?, date: Date?) -> UIViewController {
        if let radioChannel {
            return CalendarViewController(radioChannel: radioChannel, date: date)
        }
        else if !ApplicationConfiguration.shared.isTvGuideUnavailable {
            return ProgramGuideViewController(date: date)
        }
        else {
            return CalendarViewController(radioChannel: nil, date: date)
        }
    }
#endif
    
    init(id: PageViewModel.Id, fromPushNotification: Bool = false) {
        model = PageViewModel(id: id)
        self.fromPushNotification = fromPushNotification
        super.init(nibName: nil, bundle: nil)
        title = id.title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var id: PageViewModel.Id {
        return model.id
    }
    
    @objc var radioChannel: RadioChannel? {
        if case let .audio(channel: channel) = model.id {
            return channel
        }
        else {
            return nil
        }
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        
        let collectionView = CollectionView(frame: .zero, collectionViewLayout: layout(for: model))
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
        
#if os(iOS)
        if #available(iOS 17.0, *) {
            collectionView.registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (collectionView: CollectionView, _) in
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
        navigationItem.largeTitleDisplayMode = model.id.isLargeTitleDisplayMode ? .always : .never
        headerWithTitleVisible = model.id.isHeaderWithTitle
#endif
        
        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<ItemCell>, PageViewModel.Item> { [model] cell, _, item in
            cell.content = ItemCell(item: item, id: model.id)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        let globalHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<TitleView>>(elementKind: Header.global.rawValue) { [weak self] view, _, _ in
            guard let self else { return }
            view.content = TitleView(text: model.id.displayedGlobalTitle)
        }
        
        let pageHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<PageHeaderView>>(elementKind: Header.pageHeader.rawValue) { [weak self] view, _, _ in
            guard let self else { return }
            view.content = PageHeaderView(page: model.id.displayedPage)
        }
        
        let showHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<ShowHeaderView>>(elementKind: Header.showHeader.rawValue) { [weak self] view, _, _ in
            guard let self else { return }
            view.content = ShowHeaderView(show: model.id.displayedShow, horizontalPadding: Self.layoutHorizontalMargin)
        }
        
        let sectionHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<SectionHeaderView>>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] view, _, indexPath in
            guard let self else { return }
            let snapshot = dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            view.content = SectionHeaderView(section: section, pageId: model.id)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            if kind == Header.global.rawValue {
                return collectionView.dequeueConfiguredReusableSupplementary(using: globalHeaderViewRegistration, for: indexPath)
            }
            if kind == Header.pageHeader.rawValue {
                return collectionView.dequeueConfiguredReusableSupplementary(using: pageHeaderViewRegistration, for: indexPath)
            }
            if kind == Header.showHeader.rawValue {
                return collectionView.dequeueConfiguredReusableSupplementary(using: showHeaderViewRegistration, for: indexPath)
            }
            else {
                return collectionView.dequeueConfiguredReusableSupplementary(using: sectionHeaderViewRegistration, for: indexPath)
            }
        }
        
        model.$state
            .sink { [weak self] state in
                self?.trackPageView(state: state)
                self?.reloadData(for: state)
            }
            .store(in: &cancellables)
        
#if os(iOS)
        model.$serviceMessage
            .sink { serviceMessage in
                guard let serviceMessage else { return }
                Banner.show(with: .error, message: serviceMessage.text, image: nil, sticky: true)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.weakPublisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                guard let self, play_isViewCurrent else { return }
                updateNavigationBar(animated: true)
            }
            .store(in: &cancellables)
#endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateLayoutConfiguration()
        model.reload()
        deselectItems(in: collectionView, animated: animated)
#if os(iOS)
        updateNavigationBar(animated: animated)
#endif
        userActivity = model.userActivity
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        userActivity = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateLayoutConfiguration()
    }
    
    private func updateLayoutConfiguration() {
        // Update configuration supplementary views layouts (ie: show header layout).
        // Update configuration forces a collection view layout refresh. Updating only configuration.boundarySupplementaryItems does not.
        if let collectionViewLayout = self.collectionView.collectionViewLayout as? UICollectionViewCompositionalLayout {
            collectionViewLayout.configuration = Self.layoutConfiguration(model: model, layoutWidth: view.safeAreaLayoutGuide.layoutFrame.width, horizontalSizeClass: view.traitCollection.horizontalSizeClass, offsetX: view.safeAreaLayoutGuide.layoutFrame.minX)
        }
    }
    
    private func emptyViewEdgeInsets() -> EdgeInsets {
        let configuration = Self.layoutConfiguration(model: model, layoutWidth: view.safeAreaLayoutGuide.layoutFrame.width, horizontalSizeClass: view.traitCollection.horizontalSizeClass, offsetX: view.safeAreaLayoutGuide.layoutFrame.minX)
        let supplementaryItemsHeight = configuration.boundarySupplementaryItems.map { $0.layoutSize.heightDimension.dimension }.reduce(0, +)
        return EdgeInsets(top: supplementaryItemsHeight, leading: 0, bottom: 0, trailing: 0)
    }
    
    private func reloadData(for state: PageViewModel.State) {
        switch state {
        case .loading:
            emptyContentView.content = EmptyContentView(state: .loading, insets: emptyViewEdgeInsets())
        case let .failed(error: error, _):
            emptyContentView.content = EmptyContentView(state: .failed(error: error), insets: emptyViewEdgeInsets())
        case let .loaded(rows: rows, _):
            emptyContentView.content = rows.isEmpty ? EmptyContentView(state: .empty(type: .generic), insets: emptyViewEdgeInsets()) : nil
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            // Can be triggered on a background thread. Layout is updated on the main thread.
            self.dataSource.apply(Self.snapshot(from: state)) {
#if os(iOS)
                // Avoid stopping scrolling
                // See http://stackoverflow.com/a/31681037/760435
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
#endif
            }
        }
    }
    
#if os(iOS)
    private func updateNavigationBar(animated: Bool) {
        if model.id.supportsCastButton {
            if !isNavigationBarHidden, let navigationBar = navigationController?.navigationBar {
                self.googleCastButton?.removeFromSuperview()
                navigationItem.rightBarButtonItem = GoogleCastBarButtonItem(for: navigationBar)
            }
            else if self.googleCastButton == nil {
                let googleCastButton = GoogleCastFloatingButton(frame: .zero)
                view.addSubview(googleCastButton)
                self.googleCastButton = googleCastButton
                
                // Place the button where it would appear if a navigation bar was available. An offset is needed on iPads for a perfect
                // result (might be fragile but should be enough).
                let topOffset: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 3 : 0
                NSLayoutConstraint.activate([
                    googleCastButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: topOffset),
                    googleCastButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
                ])
            }
        }
        else {
            self.googleCastButton?.removeFromSuperview()
        }
        
        navigationItem.title = !headerWithTitleVisible ? title : nil
        navigationController?.setNavigationBarHidden(isNavigationBarHidden, animated: animated)
        
        if model.id.sharingItem != nil {
            let shareButtonItem = UIBarButtonItem(image: UIImage(named: "share"),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(self.shareContent(_:)))
            shareButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Share", comment: "Share button label on content page view")
            navigationItem.rightBarButtonItem = shareButtonItem
        }
        else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc private func pullToRefresh(_ refreshControl: RefreshControl) {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        refreshTriggered = true
    }
    
    @objc private func shareContent(_ barButtonItem: UIBarButtonItem) {
        guard let sharingItem = model.id.sharingItem else { return }
        
        let activityViewController = UIActivityViewController(sharingItem: sharingItem, from: .button)
        activityViewController.modalPresentationStyle = .popover
        
        let popoverPresentationController = activityViewController.popoverPresentationController
        popoverPresentationController?.barButtonItem = barButtonItem
        
        self.present(activityViewController, animated: true, completion: nil)
    }
#endif
    
    private func trackPageView(state: PageViewModel.State) {
        switch state {
        case .loading:
            break
        case let .failed(_, pageUid), let .loaded(_, pageUid):
            guard !self.analyticsPageViewTracked else { return }
            self.analyticsPageViewTracked = true
            
            SRGAnalyticsTracker.shared.trackPageView(withTitle: model.id.analyticsPageViewTitle,
                                                     type: model.id.analyticsPageViewType,
                                                     levels: model.id.analyticsPageViewLevels,
                                                     labels: model.id.analyticsPageViewLabels(pageUid: pageUid),
                                                     fromPushNotification: fromPushNotification)
        }
    }
}

// MARK: Types

private extension PageViewController {
    enum Header: String {
        case global
        case pageHeader
        case showHeader
    }
    
#if os(iOS)
    private typealias CollectionView = DampedCollectionView
#else
    private typealias CollectionView = UICollectionView
#endif
}

// MARK: Objective-C API

extension PageViewController {
    @objc static func videosViewController() -> PageViewController {
        return PageViewController(id: .video)
    }
    
    @objc static func audiosViewController(forRadioChannel channel: RadioChannel) -> PageViewController {
        return PageViewController(id: .audio(channel: channel))
    }
    
    @objc static func liveViewController() -> PageViewController {
        return PageViewController(id: .live)
    }
    
    @objc static func topicViewController(for topic: SRGTopic) -> PageViewController {
        return PageViewController(id: .topic(topic))
    }
    
    @objc static func showViewController(for show: SRGShow, fromPushNotification: Bool = false) -> PageViewController {
        return PageViewController(id: .show(show), fromPushNotification: fromPushNotification)
    }
    
    @objc static func pageViewController(for page: SRGContentPage) -> PageViewController {
        return PageViewController(id: .page(page))
    }
}

// MARK: Protocols

extension PageViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        return collectionView != nil ? [collectionView] : nil
    }
    
    var play_paddingContentInsets: UIEdgeInsets {
#if os(iOS)
        let top = (isNavigationBarHidden || model.id.isHeaderWithTitle) ? 0 : Self.layoutVerticalMargin
#else
        let top = Self.layoutVerticalMargin
#endif
        return UIEdgeInsets(top: top, left: 0, bottom: Self.layoutVerticalMargin, right: 0)
    }
}

#if os(iOS)
extension PageViewController: Oriented {
}
#endif

extension PageViewController: ScrollableContent {
    var play_scrollableView: UIScrollView? {
        return collectionView
    }
}

extension PageViewController: UICollectionViewDelegate {
#if os(iOS)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        
        switch item.wrappedValue {
        case let .item(wrappedItem):
            switch wrappedItem {
            case let .media(media):
                play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
            case let .show(show):
                if let navigationController {
                    let pageViewController = PageViewController(id: .show(show))
                    navigationController.pushViewController(pageViewController, animated: true)
                }
            case let .topic(topic):
                if let navigationController {
                    let pageViewController = PageViewController(id: .topic(topic))
                    navigationController.pushViewController(pageViewController, animated: true)
                }
            case let .highlight(_, highlightedItem):
                if let navigationController {
                    if case let .show(show) = highlightedItem {
                        let pageViewController = PageViewController(id: .show(show))
                        navigationController.pushViewController(pageViewController, animated: true)
                    }
                    else {
                        let sectionViewController = SectionViewController(section: section.wrappedValue, filter: model.id)
                        navigationController.pushViewController(sectionViewController, animated: true)
                    }
                }
            default:
                ()
            }
        case .more:
            if let navigationController {
                let sectionViewController = SectionViewController(section: section.wrappedValue, filter: model.id)
                navigationController.pushViewController(sectionViewController, animated: true)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        
        switch item.wrappedValue {
        case let .item(wrappedItem):
            return ContextMenu.configuration(for: wrappedItem, at: indexPath, in: self)
        default:
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        switch elementKind {
        case Header.showHeader.rawValue, Header.pageHeader.rawValue:
            headerWithTitleVisible = true
            updateNavigationBar(animated: true)
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        switch elementKind {
        case Header.showHeader.rawValue, Header.pageHeader.rawValue:
                headerWithTitleVisible = false
                updateNavigationBar(animated: true)
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

extension PageViewController: UIScrollViewDelegate {
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

#if os(iOS)

extension PageViewController: PlayApplicationNavigation {
    func open(_ applicationSectionInfo: ApplicationSectionInfo) -> Bool {
        guard radioChannel === applicationSectionInfo.radioChannel || radioChannel == applicationSectionInfo.radioChannel else { return false }
        
        switch applicationSectionInfo.applicationSection {
        case .showByDate:
            let date = applicationSectionInfo.options?[ApplicationSectionOptionKey.showByDateDateKey] as? Date
            if let navigationController {
                let showByDateViewController = Self.showByDateViewController(radioChannel: radioChannel, date: date)
                navigationController.pushViewController(showByDateViewController, animated: false)
            }
            return true
        case .showAZ:
            if let navigationController {
                let initialSectionId = applicationSectionInfo.options?[ApplicationSectionOptionKey.showAZIndexKey] as? String
                let showsViewController = SectionViewController.showsViewController(forChannelUid: radioChannel?.uid, initialSectionId: initialSectionId)
                navigationController.pushViewController(showsViewController, animated: false)
            }
            return true
        default:
            switch self.model.id {
            case .live:
                return applicationSectionInfo.applicationSection == .live
            default:
                return applicationSectionInfo.applicationSection == .overview
            }
        }
    }
}

extension PageViewController: ShowAccessCellActions {
    func openShowAZ() {
        if let navigationController {
            let showsViewController = SectionViewController.showsViewController(forChannelUid: radioChannel?.uid)
            navigationController.pushViewController(showsViewController, animated: true)
        }
    }
    
    func openShowByDate() {
        if let navigationController {
            let showByDateViewController = Self.showByDateViewController(radioChannel: radioChannel, date: nil)
            navigationController.pushViewController(showByDateViewController, animated: true)
        }
    }
}

extension PageViewController: SectionHeaderViewAction {
    fileprivate func openSection(sender: Any?, event: OpenSectionEvent?) {
        if let event, let navigationController {
            let sectionViewController = SectionViewController(section: event.section.wrappedValue, filter: model.id)
            navigationController.pushViewController(sectionViewController, animated: true)
        }
    }
}

extension PageViewController: TabBarActionable {
    func performActiveTabAction(animated: Bool) {
        collectionView?.play_scrollToTop(animated: animated)
    }
}

#endif

extension PageViewController: ShowHeaderViewAction {
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

// MARK: Layout

private extension PageViewController {
    private static let itemSpacing: CGFloat = constant(iOS: 8, tvOS: 40)
    private static let layoutHorizontalMargin: CGFloat = constant(iOS: 16, tvOS: 0)
    private static let layoutVerticalMargin: CGFloat = constant(iOS: 8, tvOS: 0)
    private static let layoutHorizontalConfigurationViewMargin: CGFloat = constant(iOS: 0, tvOS: 8)
    
    private static func layoutConfiguration(model: PageViewModel, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass, offsetX: CGFloat) -> UICollectionViewCompositionalLayoutConfiguration {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = constant(iOS: 35, tvOS: 70)
        configuration.contentInsetsReference = constant(iOS: .automatic, tvOS: .layoutMargins)
        
        if let show = model.id.displayedShow {
            let showHeaderSize = ShowHeaderViewSize.recommended(for: show, horizontalPadding: layoutHorizontalMargin, layoutWidth: layoutWidth - layoutHorizontalConfigurationViewMargin * 2, horizontalSizeClass: horizontalSizeClass)
            configuration.boundarySupplementaryItems = [ NSCollectionLayoutBoundarySupplementaryItem(layoutSize: showHeaderSize, elementKind: Header.showHeader.rawValue, alignment: .topLeading, absoluteOffset: CGPoint(x: offsetX + layoutHorizontalConfigurationViewMargin, y: 0)) ]
        }
        else if let globalTitle = model.id.displayedGlobalTitle {
            let globalHeaderSize = TitleViewSize.recommended(forText: globalTitle)
            configuration.boundarySupplementaryItems = [ NSCollectionLayoutBoundarySupplementaryItem(layoutSize: globalHeaderSize, elementKind: Header.global.rawValue, alignment: .topLeading, absoluteOffset: CGPoint(x: offsetX, y: 0)) ]
        }
        else if let page = model.id.displayedPage {
            let globalHeaderSize = PageHeaderViewSize.recommended(for: page, layoutWidth: layoutWidth - layoutHorizontalConfigurationViewMargin * 2, horizontalSizeClass: horizontalSizeClass)
            configuration.boundarySupplementaryItems = [ NSCollectionLayoutBoundarySupplementaryItem(layoutSize: globalHeaderSize, elementKind: Header.pageHeader.rawValue, alignment: .topLeading, absoluteOffset: CGPoint(x: offsetX, y: 0)) ]
        }
        
        return configuration
    }
    
    private func layout(for model: PageViewModel) -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, layoutEnvironment in
            let layoutWidth = layoutEnvironment.container.effectiveContentSize.width
            let horizontalSizeClass = layoutEnvironment.traitCollection.horizontalSizeClass
            
            func sectionSupplementaryItems(for section: PageViewModel.Section, horizontalMargin: CGFloat) -> [NSCollectionLayoutBoundarySupplementaryItem] {
                let headerSize = SectionHeaderView.size(section: section, layoutWidth: layoutWidth)
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .topLeading)
                return [header]
            }
            
            func horizontalMargin(for section: PageViewModel.Section) -> CGFloat {
                switch section.viewModelProperties.layout {
                case .mediaList:
#if os(iOS)
                    return horizontalSizeClass == .compact ? Self.layoutHorizontalMargin : Self.layoutHorizontalMargin * 2
#else
                    return Self.layoutHorizontalMargin
#endif
                default:
                    return Self.layoutHorizontalMargin
                }
            }
            
            func layoutSection(for section: PageViewModel.Section) -> NSCollectionLayoutSection {
                switch section.viewModelProperties.layout {
                case .heroStage:
                    let layoutSection = NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { layoutWidth, _ in
                        return HeroMediaCellSize.recommended(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
                    }
                    layoutSection.orthogonalScrollingBehavior = .groupPaging
                    return layoutSection
                case .highlight:
                    return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { layoutWidth, _ in
                        return HighlightCellSize.fullWidth(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
                    }
                case .headline:
                    let layoutSection = NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { layoutWidth, _ in
                        return FeaturedContentCellSize.headline(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
                    }
                    layoutSection.orthogonalScrollingBehavior = .groupPaging
                    return layoutSection
                case .element:
                    return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { layoutWidth, _ in
                        return FeaturedContentCellSize.element(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
                    }
                case .elementSwimlane:
                    let layoutSection = NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { layoutWidth, _ in
                        return FeaturedContentCellSize.element(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
                    }
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .mediaSwimlane:
                    let layoutSection = NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { _, _ in
                        return MediaCellSize.swimlane()
                    }
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .liveMediaSwimlane:
                    let layoutSection = NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { _, _ in
                        return LiveMediaCellSize.swimlane()
                    }
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .showSwimlane:
                    let layoutSection = NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { _, _ in
                        return ShowCellSize.swimlane(for: section.properties.imageVariant)
                    }
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .topicSelector:
                    let layoutSection = NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { _, _ in
                        return TopicCellSize.swimlane()
                    }
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .mediaGrid:
                    if horizontalSizeClass == .compact {
                        return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { _, _ in
                            return MediaCellSize.fullWidth()
                        }
                    }
                    else {
                        return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { layoutWidth, spacing in
                            return MediaCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                        }
                    }
                case .liveMediaGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { layoutWidth, spacing in
                        return LiveMediaCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                    }
                case .showGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { layoutWidth, spacing in
                        return ShowCellSize.grid(for: section.properties.imageVariant, layoutWidth: layoutWidth, spacing: spacing)
                    }
#if os(iOS)
                case .showAccess:
                    return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { _, _ in
                        return ShowAccessCellSize.fullWidth()
                    }
#endif
                case .mediaList:
#if os(iOS)
                    return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { _, _ in
                        return MediaCellSize.fullWidth(horizontalSizeClass: horizontalSizeClass)
                    }
#else
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, horizontalMargin: horizontalMargin(for: section), spacing: Self.itemSpacing) { layoutWidth, spacing in
                        return MediaCellSize.grid(layoutWidth: layoutWidth, spacing: spacing)
                    }
#endif
                }
            }
            
            guard let self else { return nil }
            
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[sectionIndex]
            
            let layoutSection = layoutSection(for: section)
            layoutSection.boundarySupplementaryItems = sectionSupplementaryItems(for: section, horizontalMargin: horizontalMargin(for: section))
            return layoutSection
        }, configuration: Self.layoutConfiguration(model: model, layoutWidth: 0, horizontalSizeClass: .unspecified, offsetX: 0))
    }
}

// MARK: Cells

private extension PageViewController {
    struct MediaCell: View {
        let media: SRGMedia?
        let section: PageViewModel.Section
        
        var body: some View {
            switch section.viewModelProperties.layout {
            case .heroStage:
                HeroMediaCell(media: media, label: section.properties.label)
            case .headline:
                FeaturedContentCell(media: media, style: haveSameShow(media: media, in: section) ? .date : .show, label: section.properties.label, layout: .headline)
            case .element, .elementSwimlane:
                FeaturedContentCell(media: media, style: haveSameShow(media: media, in: section) ? .date : .show, label: section.properties.label, layout: .element)
            case .liveMediaSwimlane, .liveMediaGrid:
                LiveMediaCell(media: media)
            case .mediaGrid:
                PlaySRG.MediaCell(media: media, style: haveSameShow(media: media, in: section) ? .date : .show)
            case .mediaList:
                PlaySRG.MediaCell(media: media, style: .dateAndSummary, layout: .horizontal)
            default:
                PlaySRG.MediaCell(media: media, style: haveSameShow(media: media, in: section) ? .date : .show, layout: .vertical)
            }
        }
        
        private func haveSameShow(media: SRGMedia?, in section: PageViewModel.Section) -> Bool {
            guard let displayedShow = section.properties.displayedShow, let mediaShow = media?.show else { return false }
            
            return displayedShow.isEqual(mediaShow)
        }
    }
    
    struct ShowCell: View {
        let show: SRGShow?
        let section: PageViewModel.Section
        
        var body: some View {
            switch section.viewModelProperties.layout {
            case .heroStage, .headline:
                FeaturedContentCell(show: show, label: section.properties.label, layout: .headline)
            case .element:
                FeaturedContentCell(show: show, label: section.properties.label, layout: .element)
            default:
                PlaySRG.ShowCell(show: show, style: .standard, imageVariant: section.properties.imageVariant)
            }
        }
    }
    
    struct ItemCell: View {
        let item: PageViewModel.Item
        let id: PageViewModel.Id
        
        var body: some View {
            switch item.wrappedValue {
            case let .item(wrappedItem):
                switch wrappedItem {
                case .mediaPlaceholder:
                    MediaCell(media: nil, section: item.section)
                case let .media(media):
                    MediaCell(media: media, section: item.section)
                case .showPlaceholder:
                    ShowCell(show: nil, section: item.section)
                case let .show(show):
                    ShowCell(show: show, section: item.section)
                case .topicPlaceholder:
                    TopicCell(topic: nil)
                case let .topic(topic):
                    TopicCell(topic: topic)
#if os(iOS)
                case let .download(download):
                    DownloadCell(download: download)
                case let .notification(notification):
                    NotificationCell(notification: notification)
                case .showAccess:
                    switch id {
                    case .video:
                        let style: ShowAccessCell.Style = !ApplicationConfiguration.shared.isTvGuideUnavailable ? .programGuide : .calendar
                        ShowAccessCell(style: style)
                    default:
                        ShowAccessCell(style: .calendar)
                    }
#endif
                case .highlightPlaceholder:
                    HighlightCell(highlight: nil, section: item.section.wrappedValue, item: nil, filter: id)
                case let .highlight(highlight, highlightedItem):
                    HighlightCell(highlight: highlight, section: item.section.wrappedValue, item: highlightedItem, filter: id)
                case .transparent:
                    Color.clear
                }
            case .more:
                MoreCell(section: item.section.wrappedValue, imageVariant: item.section.properties.imageVariant, filter: id)
            }
        }
    }
}

// MARK: Headers

@objc private protocol SectionHeaderViewAction {
    func openSection(sender: Any?, event: OpenSectionEvent?)
}

private class OpenSectionEvent: UIEvent {
    let section: PageViewModel.Section
    
    init(section: PageViewModel.Section) {
        self.section = section
        super.init()
    }
    
    override init() {
        fatalError("init() is not available")
    }
}

private extension PageViewController {
    private struct SectionHeaderView: View {
        let section: PageViewModel.Section
        let pageId: PageViewModel.Id
        
        @FirstResponder private var firstResponder
        @AppStorage(PlaySRGSettingSectionWideSupportEnabled) var isSectionWideSupportEnabled = false
        
        private static func title(for section: PageViewModel.Section) -> String? {
            return section.properties.title
        }
        
        private static func subtitle(for section: PageViewModel.Section) -> String? {
            return section.properties.summary
        }
        
        private var hasDetailDisclosure: Bool {
            return section.viewModelProperties.canOpenDetailPage || isSectionWideSupportEnabled
        }
        
        var accessibilityLabel: String? {
            return Self.title(for: section)
        }
        
        var accessibilityHint: String? {
            return hasDetailDisclosure ? PlaySRGAccessibilityLocalizedString("Shows all contents.", comment: "Homepage header action hint") : nil
        }
        
        var body: some View {
            if section.properties.displaysRowHeader, let title = Self.title(for: section) {
#if os(tvOS)
                HeaderView(title: title, subtitle: Self.subtitle(for: section), hasDetailDisclosure: false)
#else
                Button {
                    firstResponder.sendAction(#selector(SectionHeaderViewAction.openSection(sender:event:)), for: OpenSectionEvent(section: section))
                } label: {
                    HeaderView(title: title, subtitle: Self.subtitle(for: section), hasDetailDisclosure: hasDetailDisclosure)
                }
                .disabled(!hasDetailDisclosure)
                .responderChain(from: firstResponder)
#endif
            }
        }
        
        static func size(section: PageViewModel.Section, layoutWidth: CGFloat) -> NSCollectionLayoutSize {
            if section.properties.displaysRowHeader {
                return HeaderViewSize.recommended(forTitle: title(for: section), subtitle: subtitle(for: section), layoutWidth: layoutWidth)
            }
            else {
                return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
            }
        }
    }
}
