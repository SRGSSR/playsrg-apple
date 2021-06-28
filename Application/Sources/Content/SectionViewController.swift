//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAppearanceSwift
import SwiftUI
import UIKit

// MARK: View controller

class SectionViewController: UIViewController {
    let model: SectionViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    private var dataSource: UICollectionViewDiffableDataSource<SectionViewModel.Section, SectionViewModel.Item>!
    
    private weak var collectionView: UICollectionView!
    private weak var emptyView: HostView<EmptyView>!
    
    #if os(iOS)
    private weak var refreshControl: UIRefreshControl!
    #endif
    
    private var refreshTriggered = false
    
    private var globalHeaderTitle: String? {
        #if os(tvOS)
        return model.title
        #else
        return nil
        #endif
    }
    
    private static func snapshot(from state: SectionViewModel.State) -> NSDiffableDataSourceSnapshot<SectionViewModel.Section, SectionViewModel.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<SectionViewModel.Section, SectionViewModel.Item>()
        if case let .loaded(headerItem: _, row: row) = state {
            snapshot.appendSections([row.section])
            snapshot.appendItems(row.items, toSection: row.section)
        }
        return snapshot
    }
    
    init(section: Content.Section, filter: SectionFiltering? = nil) {
        model = SectionViewModel(section: section, filter: filter)
        super.init(nibName: nil, bundle: nil)
        title = model.title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray1
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let emptyView = HostView<EmptyView>(frame: .zero)
        collectionView.backgroundView = emptyView
        self.emptyView = emptyView
        
        #if os(tvOS)
        self.tabBarObservedScrollView = collectionView
        #else
        let refreshControl = RefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.insertSubview(refreshControl, at: 0)
        self.refreshControl = refreshControl
        #endif
        
        #if os(iOS)
        if model.section.properties.sharingItem != nil {
            let shareButtonItem = UIBarButtonItem(image: UIImage(named: "share"),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(self.shareContent(_:)))
            shareButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Share", "Share button label on player view")
            navigationItem.rightBarButtonItem = shareButtonItem
        }
        #endif
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<ItemCell>, SectionViewModel.Item> { cell, _, item in
            cell.content = ItemCell(item: item)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        let globalHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<TitleView>>(elementKind: Header.global.rawValue) { [weak self] view, _, _ in
            guard let self = self else { return }
            view.content = TitleView(text: self.globalHeaderTitle)
        }
        
        let sectionHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<SectionHeaderView>>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] view, _, indexPath in
            guard let self = self else { return }
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            view.content = SectionHeaderView(section: section, headerItem: self.model.state.headerItem)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            if kind == Header.global.rawValue {
                return collectionView.dequeueConfiguredReusableSupplementary(using: globalHeaderViewRegistration, for: indexPath)
            }
            else {
                return collectionView.dequeueConfiguredReusableSupplementary(using: sectionHeaderViewRegistration, for: indexPath)
            }
        }
                
        model.$state
            .sink { [weak self] state in
                self?.reloadData(for: state)
            }
            .store(in: &cancellables)
    }
    
    #if os(iOS)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
    #endif
    
    func reloadData(for state: SectionViewModel.State) {
        switch state {
        case .loading:
            emptyView.content = EmptyView(state: .loading)
        case let .failed(error: error):
            emptyView.content = EmptyView(state: .failed(error: error))
        case let .loaded(headerItem: _, row: row):
            emptyView.content = row.isEmpty ? EmptyView(state: .empty) : nil
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
                self.play_setNeedsContentInsetsUpdate()
            }
        }
    }
    
    #if os(iOS)
    @objc func pullToRefresh(_ refreshControl: RefreshControl) {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        refreshTriggered = true
    }
    
    @objc func shareContent(_ barButtonItem: UIBarButtonItem) {
        guard let sharingItem = model.section.properties.sharingItem else { return }
        
        let activityViewController = UIActivityViewController(sharingItem: sharingItem, source: .button, in: self)
        activityViewController.modalPresentationStyle = .popover
        
        let popoverPresentationController = activityViewController.popoverPresentationController
        popoverPresentationController?.barButtonItem = barButtonItem
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    #endif
}

// MARK: Types

private extension SectionViewController {
    enum Header: String {
        case global
    }
}

// MARK: Objective-C constructors

extension SectionViewController {
    @objc static func viewController(for contentSection: SRGContentSection) -> SectionViewController {
        return SectionViewController(section: .content(contentSection))
    }
}

// MARK: Protocols

extension SectionViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        return collectionView != nil ? [collectionView] : nil
    }
    
    var play_paddingContentInsets: UIEdgeInsets {
        let top = (model.state.headerItem != nil) ? 0 : Self.layoutVerticalMargin
        return UIEdgeInsets(top: top, left: 0, bottom: Self.layoutVerticalMargin, right: 0)
    }
}

extension SectionViewController: UICollectionViewDelegate {
    #if os(iOS)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        
        switch item {
        case let .media(media):
            play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
        case let .show(show):
            if let navigationController = navigationController {
                let showViewController = ShowViewController(show: show, fromPushNotification: false)
                navigationController.pushViewController(showViewController, animated: true)
            }
        case let .topic(topic):
            if let navigationController = navigationController {
                let pageViewController = PageViewController(id: .topic(topic: topic))
                navigationController.pushViewController(pageViewController, animated: true)
            }
        default:
            ()
        }
            
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        return ContextMenu.configuration(for: item, at: indexPath, in: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        ContextMenu.commitPreview(in: self, animator: animator)
    }
    
    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let interactionView = ContextMenu.interactionView(in: collectionView, withIdentifier: configuration.identifier) else { return nil }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = view.backgroundColor
        return UITargetedPreview(view: interactionView, parameters: parameters)
    }
    
    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let interactionView = ContextMenu.interactionView(in: collectionView, withIdentifier: configuration.identifier) else { return nil }
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
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Avoid the collection jumping when pulling to refresh. Only mark the refresh as being triggered.
        if refreshTriggered {
            model.reload()
            refreshTriggered = false
        }
    }
    
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
        return model.section.properties.analyticsTitle ?? ""
    }
    
    var srg_pageViewLevels: [String]? {
        return model.section.properties.analyticsLevels
    }
}

extension SectionViewController: SectionShowHeaderViewAction {
    func openShow(sender: Any?, event: OpenShowEvent?) {
        #if os(tvOS)
        if let event = event {
            navigateToShow(event.show)
        }
        #else
        if let event = event, let navigationController = navigationController {
            let showViewController = ShowViewController(show: event.show, fromPushNotification: false)
            navigationController.pushViewController(showViewController, animated: true)
        }
        #endif
    }
}

// MARK: Layout

private extension SectionViewController {
    private static let itemSpacing: CGFloat = constant(iOS: 8, tvOS: 40)
    private static let layoutVerticalMargin: CGFloat = constant(iOS: 8, tvOS: 0)
    
    private func layoutConfiguration() -> UICollectionViewCompositionalLayoutConfiguration {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = constant(iOS: .automatic, tvOS: .layoutMargins)
        
        let headerSize = TitleViewSize.recommended(text: globalHeaderTitle)
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: Header.global.rawValue, alignment: .topLeading)
        configuration.boundarySupplementaryItems = [header]
        
        return configuration
    }
    
    private func layout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, layoutEnvironment in
            func sectionSupplementaryItems(for section: SectionViewModel.Section, index: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> [NSCollectionLayoutBoundarySupplementaryItem] {
                let headerSize = SectionHeaderView.size(section: section,
                                                        headerItem: self?.model.state.headerItem,
                                                        layoutWidth: layoutEnvironment.container.effectiveContentSize.width,
                                                        horizontalSizeClass: layoutEnvironment.traitCollection.horizontalSizeClass)
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                return [header]
            }
            
            func layoutSection(for section: SectionViewModel.Section, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
                let layoutWidth = layoutEnvironment.container.effectiveContentSize.width
                let horizontalSizeClass = layoutEnvironment.traitCollection.horizontalSizeClass
                
                switch section.viewModelProperties.layout {
                case .mediaGrid:
                    if horizontalSizeClass == .compact {
                        return NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth, spacing: Self.itemSpacing) { _ in
                            return MediaCellSize.fullWidth()
                        }
                    }
                    else {
                        return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing) { layoutWidth, spacing in
                            return MediaCellSize.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing, minimumNumberOfColumns: 1)
                        }
                    }
                case .liveMediaGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing) { layoutWidth, spacing in
                        return LiveMediaCellSize.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing, minimumNumberOfColumns: 2)
                    }
                case .showGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing) { layoutWidth, spacing in
                        return ShowCellSize.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing, minimumNumberOfColumns: 2)
                    }
                case .topicGrid:
                    return NSCollectionLayoutSection.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing) { layoutWidth, spacing in
                        return TopicCellSize.grid(layoutWidth: layoutWidth, spacing: Self.itemSpacing, minimumNumberOfColumns: 2)
                    }
                }
            }
            
            guard let self = self else { return nil }
            
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[sectionIndex]
            
            let layoutSection = layoutSection(for: section, layoutEnvironment: layoutEnvironment)
            layoutSection.boundarySupplementaryItems = sectionSupplementaryItems(for: section, index: sectionIndex, layoutEnvironment: layoutEnvironment)
            return layoutSection
        }, configuration: layoutConfiguration())
    }
}

// MARK: Cells

private extension SectionViewController {
    struct ItemCell: View {
        let item: SectionViewModel.Item
        
        var body: some View {
            switch item {
            case let .media(media):
                MediaCell(media: media, style: .show)
            case let .show(show):
                ShowCell(show: show)
            case let .topic(topic: topic):
                TopicCell(topic: topic)
            default:
                MediaCell(media: nil)
            }
        }
    }
}

// MARK: Headers

private extension SectionViewController {
    struct SectionHeaderView: View {
        let section: SectionViewModel.Section
        let headerItem: SectionViewModel.Item?
        
        var body: some View {
            switch headerItem {
            case let .show(show):
                SectionShowHeaderView(section: section.wrappedValue, show: show)
            default:
                Color.clear
            }
        }
        
        static func size(section: SectionViewModel.Section, headerItem: SectionViewModel.Item?, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
            switch headerItem {
            case let .show(show):
                return SectionShowHeaderViewSize.recommended(for: section.wrappedValue, show: show, layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass)
            default:
                return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
            }
        }
    }
}
