//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import DZNEmptyDataSet
import SRGAppearanceSwift
import SRGDataProviderModel
import UIKit

class PageViewController: DataViewController {
    private let model: PageModel
    private var refreshCancellables = Set<AnyCancellable>()

    private var dataSource: UICollectionViewDiffableDataSource<PageModel.Section, PageModel.Item>!
    
    private weak var collectionView: UICollectionView!
    private var loadingImageView: UIImageView!
    
    #if os(iOS)
    private weak var refreshControl: UIRefreshControl!
    #else
    private weak var titleView: PageTitleView!
    #endif
    
    // Deal with intermediate collection view asynchronous reload state, which is not part of the model but an
    // an implementation detail. This helps `DZNEmptyDataSet` for which the collection might be empty while it
    // is in fact rendering data.
    private var reloadCount = 0
    private var refreshTriggered = false
    
    #if os(iOS)
    private typealias CollectionView = DampedCollectionView
    #else
    private typealias CollectionView = UICollectionView
    #endif
    
    @objc static func videosViewController() -> UIViewController {
        return PageViewController(id: .video)
    }
    
    @objc static func audiosViewController(forRadioChannel channel: RadioChannel) -> UIViewController {
        return PageViewController(id: .audio(channel: channel))
    }
    
    @objc static func liveViewController() -> UIViewController {
        return PageViewController(id: .live)
    }
    
    @objc static func topicViewController(for topic: SRGTopic) -> UIViewController {
        return PageViewController(id: .topic(topic: topic))
    }
    
    private static func snapshot(from state: PageModel.State) -> NSDiffableDataSourceSnapshot<PageModel.Section, PageModel.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<PageModel.Section, PageModel.Item>()
        if case let .loaded(rows: rows) = state {
            for row in rows {
                snapshot.appendSections([row.section])
                snapshot.appendItems(row.items, toSection: row.section)
            }
        }
        return snapshot
    }
    
    private func layout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            func sectionSupplementaryItems(for section: PageModel.Section, index: Int) -> [NSCollectionLayoutBoundarySupplementaryItem] {
                let headerSize = PageSectionHeaderView.size(section: section, layoutWidth: layoutEnvironment.container.effectiveContentSize.width)
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(headerSize.width), heightDimension: .absolute(headerSize.height)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .topLeading
                )
                return [header]
            }
            
            func layoutSection(for section: PageModel.Section, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
                switch section.properties.layout {
                case .hero:
                    let cellSize = FeaturedContentCellSize.hero(layoutWidth: layoutEnvironment.container.effectiveContentSize.width, horizontalSizeClass: layoutEnvironment.traitCollection.horizontalSizeClass)
                    let layoutSection = NSCollectionLayoutSection.horizontal(cellSize: cellSize)
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .highlight:
                    let cellSize = FeaturedContentCellSize.highlight(layoutWidth: layoutEnvironment.container.effectiveContentSize.width, horizontalSizeClass: layoutEnvironment.traitCollection.horizontalSizeClass)
                    return NSCollectionLayoutSection.horizontal(cellSize: cellSize)
                case .mediaSwimlane:
                    let layoutSection = NSCollectionLayoutSection.horizontal(cellSize: MediaCellSize.swimlane())
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .liveMediaSwimlane:
                    let layoutSection = NSCollectionLayoutSection.horizontal(cellSize: LiveMediaCellSize.swimlane())
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .showSwimlane:
                    let layoutSection = NSCollectionLayoutSection.horizontal(cellSize: ShowCellSize.swimlane())
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .topicSelector:
                    let layoutSection = NSCollectionLayoutSection.horizontal(cellSize: TopicCellSize.swimlane())
                    layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                    return layoutSection
                case .mediaGrid:
                    if layoutEnvironment.traitCollection.horizontalSizeClass == .compact {
                        return NSCollectionLayoutSection.horizontal(cellSize: MediaCellSize.fullWidth(layoutWidth: layoutEnvironment.container.effectiveContentSize.width))
                    }
                    else {
                        return NSCollectionLayoutSection.grid(cellSize: MediaCellSize.grid(layoutWidth: layoutEnvironment.container.effectiveContentSize.width, spacing: 0, minimumNumberOfColumns: 1))
                    }
                case .liveMediaGrid:
                    return NSCollectionLayoutSection.grid(cellSize: LiveMediaCellSize.grid(layoutWidth: layoutEnvironment.container.effectiveContentSize.width, spacing: 0, minimumNumberOfColumns: 2))
                case .showGrid:
                    return NSCollectionLayoutSection.grid(cellSize: ShowCellSize.grid(layoutWidth: layoutEnvironment.container.effectiveContentSize.width, spacing: 0, minimumNumberOfColumns: 2))
                #if os(iOS)
                case .showAccess:
                    return NSCollectionLayoutSection.horizontal(cellSize: ShowAccessCellSize.fullWidth(layoutWidth: layoutEnvironment.container.effectiveContentSize.width))
                #endif
                }
            }
            
            guard let self = self else { return nil }
            
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[sectionIndex]
            
            let layoutSection = layoutSection(for: section, layoutEnvironment: layoutEnvironment)
            layoutSection.boundarySupplementaryItems = sectionSupplementaryItems(for: section, index: sectionIndex)
            return layoutSection
        }
    }
    
    init(id: PageModel.Id) {
        self.model = PageModel(id: id)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        view.backgroundColor = .play_black
        
        let collectionView = CollectionView(frame: .zero, collectionViewLayout: layout())
        collectionView.delegate = self
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        
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
        
        #if os(tvOS)
        self.tabBarObservedScrollView = collectionView
        #else
        let refreshControl = RefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.insertSubview(refreshControl, at: 0)
        self.refreshControl = refreshControl
        #endif
        
        #if os(tvOS)
        // Add a global header view to the collection (like `tableHeaderView`), see https://stackoverflow.com/a/18015870/760435
        let titleView = PageTitleView()
        titleView.text = model.title
        collectionView.insertSubview(titleView, at: 0)
        self.titleView = titleView
        #endif
        
        // DZNEmptyDataSet stretches custom views horizontally. Ensure the image stays centered and does not get
        // stretched
        loadingImageView = UIImageView.play_loadingImageView90(withTintColor: .play_lightGray)
        loadingImageView.contentMode = .center
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<PageCell>, PageModel.Item> { cell, _, item in
            cell.content = PageCell(item: item)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        // TODO: Create custom registration method having the data source as parameter, and providing the section directly
        let sectionHeaderViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<PageSectionHeaderView>>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] view, _, indexPath in
            guard let self = self else { return }
            
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            
            view.content = PageSectionHeaderView(section: section)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: sectionHeaderViewRegistration, for: indexPath)
        }
        
        model.$state
            .sink { [weak self] state in
                self?.reloadData(with: state)
            }
            .store(in: &refreshCancellables)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        #if os(tvOS)
        let titleHeight = PageTitleView.size(text: model.title, layoutWidth: view.frame.width).height
        titleView.frame = CGRect(x: 0, y: -titleHeight, width: view.frame.size.width, height: titleHeight)
        titleView.isHidden = (titleHeight == 0)
        #endif
        
        collectionView.reloadEmptyDataSet()
    }
    
    #if os(iOS)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
    #endif
    
    override func refresh() {
        model.refresh()
    }
    
    func reloadData(with state: PageModel.State) {
        reloadCount += 1
        DispatchQueue.global(qos: .userInteractive).async {
            // Can be triggered on a background thread. Layout is updated on the main thread.
            self.dataSource.apply(Self.snapshot(from: state)) {
                self.reloadCount -= 1
                self.collectionView.reloadEmptyDataSet()
                
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
    @objc func pullToRefresh(_ refreshControl: RefreshControl) {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        refreshTriggered = true
    }
    #endif
}

extension PageViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        return collectionView != nil ? [collectionView] : nil
    }
    
    var play_paddingContentInsets: UIEdgeInsets {
        let titleHeight = PageTitleView.size(text: model.title, layoutWidth: view.frame.width).height
        return UIEdgeInsets(top: titleHeight, left: 0, bottom: 0, right: 0)
    }
}

extension PageViewController: UICollectionViewDelegate {
    #if os(iOS)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        
        switch item {
        case let .media(media, section: _):
            play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
        case let .show(show, section: _):
            if let navigationController = navigationController {
                let showViewController = ShowViewController(show: show, fromPushNotification: false)
                navigationController.pushViewController(showViewController, animated: true)
            }
        case let .topic(topic, section: _):
            if let navigationController = navigationController {
                let pageViewController = PageViewController(id: .topic(topic: topic))
                // TODO: Should the title be managed based on the PageViewController id? Depending on the answer,
                //       check -[PlayAppDelegate openTopicURN:]
                pageViewController.title = topic.title
                navigationController.pushViewController(pageViewController, animated: true)
            }
        default:
            ()
        }
    }
    #endif
    
    #if os(tvOS)
    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    #endif
}

extension PageViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Avoid the collection jumping when pulling to refresh. Only mark the refresh as being triggered.
        if refreshTriggered {
            refresh()
            refreshTriggered = false
        }
    }
}

extension PageViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        // When the collection view is asynchronously refreshed (short and efficient, but still not instantaneous
        // and thus noticeable), display nothing if we already have content loaded.
        if reloadCount != 0 {
            if case let .loaded(rows: rows) = model.state, rows.count != 0 {
                return UIView()
            }
            else {
                return loadingImageView
            }
        }
        // No async collection refresh is being made. Relying on the view model suffices.
        else {
            if case .loading = model.state {
                return loadingImageView
            }
            else {
                return nil
            }
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        func titleString() -> String {
            if case let .failed(error: error) = model.state {
                return error.localizedDescription
            }
            else {
                return NSLocalizedString("No results", comment: "Default text displayed when no results are available")
            }
        }
        return NSAttributedString(string: titleString(),
                                  attributes: [
                                    NSAttributedString.Key.font: SRGFont.font(.H1) as UIFont,
                                    NSAttributedString.Key.foregroundColor: UIColor.play_lightGray
                                  ])
    }
    
    #if os(iOS)
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Pull to reload", comment: "Text displayed to inform the user she can pull a list to reload it"),
                                  attributes: [
                                    NSAttributedString.Key.font: SRGFont.font(.subtitle) as UIFont,
                                    NSAttributedString.Key.foregroundColor: UIColor.play_lightGray
                                  ])
    }
    #endif
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        if case.failed = model.state {
            return UIImage(named: "error-90")
        }
        else {
            return UIImage(named: "media-90")
        }
    }
    
    func imageTintColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return .play_lightGray
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return VerticalOffsetForEmptyDataSet(scrollView)
    }
}

extension PageViewController: DZNEmptyDataSetDelegate {
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }
}

#if os(iOS)
extension PageViewController: ShowAccessCellActions {
    func openShowAZ() {
        if let navigationController = navigationController {
            let showsViewController = ShowsViewController(radioChannel: radioChannel, alphabeticalIndex: nil)
            navigationController.pushViewController(showsViewController, animated: true)
        }
    }
    
    func openShowByDate() {
        if let navigationController = navigationController {
            let calendarViewController = CalendarViewController(radioChannel: radioChannel, date: nil)
            navigationController.pushViewController(calendarViewController, animated: true)
        }
    }
}

extension PageViewController: TabBarActionable {
    func performActiveTabAction(animated: Bool) {
        collectionView.play_scrollToTop(animated: animated)
    }
}
#endif

// TODO: Remaining protocols to implement, as was the case for HomeViewController

#if false

extension PageViewController: PlayApplicationNavigation {
    
}

extension PageViewController: SRGAnalyticsViewTracking {
    
}

#endif
