//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderModel
import UIKit

class PageViewController: DataViewController {
    private let model: PageModel
    private var cancellables = Set<AnyCancellable>()
    
    private var dataSource: UICollectionViewDiffableDataSource<PageModel.Section, PageModel.Item>!
    
    private weak var collectionView: UICollectionView!
    private weak var refreshControl: UIRefreshControl!
    
    private var refreshTriggered = false
    
    @objc static func videosViewController() -> UIViewController {
        return PageViewController(id: .video)
    }
    
    @objc static func audiosViewController(forRadioChannel channel: RadioChannel) -> UIViewController {
        return PageViewController(id: .audio(channel: channel))
    }
    
    @objc static func liveViewController() -> UIViewController {
        return PageViewController(id: .live)
    }
    
    private static func snapshot(withRows rows: [PageModel.Row]) -> NSDiffableDataSourceSnapshot<PageModel.Section, PageModel.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<PageModel.Section, PageModel.Item>()
        for row in rows {
            snapshot.appendSections([row.section])
            snapshot.appendItems(row.items, toSection: row.section)
        }
        return snapshot
    }
    
    private static func layout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(210), heightDimension: .absolute(118))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
            section.interGroupSpacing = LayoutStandardMargin
            return section
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
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.layout())
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
        
        let refreshControl = RefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.insertSubview(refreshControl, at: 0)
        self.refreshControl = refreshControl
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mediaCellIdentifier = "MediaCell"
        collectionView.register(HostCollectionViewCell<MediaCell>.self, forCellWithReuseIdentifier: mediaCellIdentifier)
        
        let showCellIdentifier = "ShowCell"
        collectionView.register(HostCollectionViewCell<ShowCell>.self, forCellWithReuseIdentifier: showCellIdentifier)
        
        let topicCellIdentifier = "TopicCell"
        collectionView.register(HostCollectionViewCell<TopicCell>.self, forCellWithReuseIdentifier: topicCellIdentifier)
        
        let showAccessCellIdentifier = "ShowAccessCell"
        collectionView.register(HostCollectionViewCell<ShowAccessCell>.self, forCellWithReuseIdentifier: showAccessCellIdentifier)
        
        // TODO: Factor out cell dequeue code per type
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item.content {
            case let .media(media):
                let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: mediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<MediaCell>
                mediaCell?.content = MediaCell(media: media)
                return mediaCell
            case .mediaPlaceholder:
                let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: mediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<MediaCell>
                mediaCell?.content = MediaCell(media: nil)
                return mediaCell
            case let .show(show):
                let showCell = collectionView.dequeueReusableCell(withReuseIdentifier: showCellIdentifier, for: indexPath) as? HostCollectionViewCell<ShowCell>
                showCell?.content = ShowCell(show: show)
                return showCell
            case .showPlaceholder:
                let showCell = collectionView.dequeueReusableCell(withReuseIdentifier: showCellIdentifier, for: indexPath) as? HostCollectionViewCell<ShowCell>
                showCell?.content = ShowCell(show: nil)
                return showCell
            case let .topic(topic):
                let topicCell = collectionView.dequeueReusableCell(withReuseIdentifier: topicCellIdentifier, for: indexPath) as? HostCollectionViewCell<TopicCell>
                topicCell?.content = TopicCell(topic: topic)
                return topicCell
            case .topicPlaceholder:
                let topicCell = collectionView.dequeueReusableCell(withReuseIdentifier: topicCellIdentifier, for: indexPath) as? HostCollectionViewCell<TopicCell>
                topicCell?.content = TopicCell(topic: nil)
                return topicCell
            case .showAccess:
                let showAccessCell = collectionView.dequeueReusableCell(withReuseIdentifier: showAccessCellIdentifier, for: indexPath) as? HostCollectionViewCell<ShowAccessCell>
                showAccessCell?.content = ShowAccessCell(radioChannel: nil)
                return showAccessCell
            }
        }
        
        model.$rows
            .sink { rows in
                self.reloadData(withRows: rows)
            }
            .store(in: &cancellables)
    }
    
    override func refresh() {
        model.refresh()
    }
    
    func reloadData(withRows rows: [PageModel.Row]) {
        // Can be triggered on a background thread. Layout is updated on the main thread.
        DispatchQueue.global(qos: .userInteractive).async {
            self.dataSource.apply(Self.snapshot(withRows: rows)) {
                // Avoid stopping scrolling
                // See http://stackoverflow.com/a/31681037/760435
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    @objc func pullToRefresh(_ refreshControl: RefreshControl) {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        refreshTriggered = true
    }
}

extension PageViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        return collectionView != nil ? [collectionView] : nil
    }
    
    var play_paddingContentInsets: UIEdgeInsets {
        return LayoutStandardTableViewPaddingInsets
    }
}

extension PageViewController: UICollectionViewDelegate {
    
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

// TODO: Remaining protocols to implement, as was the case for HomeViewController

#if false

extension PageViewController: DZNEmptyDataSetSource {
    
}

extension PageViewController: DZNEmptyDataSetDelegate {
    
}

extension PageViewController: PlayApplicationNavigation {
    
}

extension PageViewController: SRGAnalyticsViewTracking {
    
}

extension PageViewController: TabBarActionable {
    
}

#endif
