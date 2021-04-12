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
    private var cancellables = Set<AnyCancellable>()
    
    private var dataSource: UICollectionViewDiffableDataSource<PageModel.Section, PageModel.Item>!
    
    private weak var collectionView: UICollectionView!
    private var loadingImageView: UIImageView!
    
    @available (tvOS, unavailable)
    private weak var refreshControl: UIRefreshControl!
    
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
            func sectionHeaderHeight(for section: PageModel.Section, index: Int, pageTitle: String?) -> CGFloat? {
                if index == 0, section.properties.title == nil, pageTitle == nil {
                    return nil
                }
                
                var height: CGFloat = LayoutStandardMargin
                if let title = section.properties.title, !title.isEmpty {
                    height += LayoutCollectionSectionHeaderTitleHeight()
                }
                if let summary = section.properties.summary, !summary.isEmpty {
                    height += (LayoutCollectionSectionHeaderTitleHeight() * 2 / 3).rounded(.up)
                }
                if let pageTitle = pageTitle, !pageTitle.isEmpty {
                    height += LayoutCollectionSectionHeaderTitleHeight()
                }
                return height
            }
            
            func supplementaryItems(for section: PageModel.Section, index: Int, pageTitle: String?) -> [NSCollectionLayoutBoundarySupplementaryItem] {
                guard let headerHeight = sectionHeaderHeight(for: section, index: index, pageTitle: pageTitle) else { return [] }
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(headerHeight)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .topLeading
                )
                return [header]
            }
            
            func layoutGroupSize(for section: PageModel.Section, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSize {
                switch section.properties.layout {
                case .hero:
                    let width = LayoutCollectionItemFeaturedWidth(layoutEnvironment.container.effectiveContentSize.width)
                    let size = LayoutMediaStandardCollectionItemSize(width, .hero)
                    return NSCollectionLayoutSize(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
                case .highlight:
                    let width = LayoutCollectionItemFeaturedWidth(layoutEnvironment.container.effectiveContentSize.width)
                    let size = LayoutMediaStandardCollectionItemSize(width, .highlight)
                    return NSCollectionLayoutSize(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
                case .topicSelector:
                    let size = LayoutTopicCollectionItemSize()
                    return NSCollectionLayoutSize(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
                case .shows:
                    let size = LayoutShowStandardCollectionItemSize(LayoutStandardCellWidth, .swimlane)
                    return NSCollectionLayoutSize(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
                case .medias:
                    let size = LayoutMediaStandardCollectionItemSize(LayoutStandardCellWidth, .swimlane)
                    return NSCollectionLayoutSize(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
                case .showAccess:
                    let size = LayoutShowAccessCollectionItemSize(layoutEnvironment.container.effectiveContentSize.width)
                    return NSCollectionLayoutSize(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
                }
            }
            
            func continuousGroupLeadingBoundary(for section: PageModel.Section) -> UICollectionLayoutSectionOrthogonalScrollingBehavior {
                switch section.properties.layout {
                case .hero:
                #if os(tvOS)
                    // Do not use .continuousGroupLeadingBoundary for full-width items on tvOS, otherwise items will
                    // be skipped when navigating the group
                    return .continuous
                #else
                    return .continuousGroupLeadingBoundary
                #endif
                case .highlight, .showAccess:
                    return .none
                default:
                    return .continuousGroupLeadingBoundary
                }
            }
            
            func contentInsets(for section: PageModel.Section) -> NSDirectionalEdgeInsets {
                switch section.properties.layout {
                case .topicSelector:
                    return LayoutTopicSectionContentInsets
                default:
                    return LayoutStandardSectionContentInsets
                }
            }
            
            guard let self = self else { return nil }
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[sectionIndex]
            let groupSize = layoutGroupSize(for: section, layoutEnvironment: layoutEnvironment)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let layoutSection = NSCollectionLayoutSection(group: group)
            layoutSection.orthogonalScrollingBehavior = continuousGroupLeadingBoundary(for: section)
            layoutSection.interGroupSpacing = LayoutStandardMargin
            layoutSection.contentInsets = contentInsets(for: section)
            layoutSection.boundarySupplementaryItems = supplementaryItems(for: section, index: sectionIndex, pageTitle: self.model.title)
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
        
        // DZNEmptyDataSet stretches custom views horizontally. Ensure the image stays centered and does not get
        // stretched
        loadingImageView = UIImageView.play_loadingImageView90(withTintColor: .play_lightGray)
        loadingImageView.contentMode = .center
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pageSectionHeaderViewIdentifier = "PageSectionHeaderView"
        collectionView.register(HostSupplementaryView<PageSectionHeaderView>.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: pageSectionHeaderViewIdentifier)
        
        let mediaCellIdentifier = "MediaCell"
        collectionView.register(HostCollectionViewCell<MediaCell>.self, forCellWithReuseIdentifier: mediaCellIdentifier)
        
        let liveMediaCellIdentifier = "LiveMediaCell"
        collectionView.register(HostCollectionViewCell<LiveMediaCell>.self, forCellWithReuseIdentifier: liveMediaCellIdentifier)
       
        let showCellIdentifier = "ShowCell"
        collectionView.register(HostCollectionViewCell<ShowCell>.self, forCellWithReuseIdentifier: showCellIdentifier)
        
        let topicCellIdentifier = "TopicCell"
        collectionView.register(HostCollectionViewCell<TopicCell>.self, forCellWithReuseIdentifier: topicCellIdentifier)
        
        #if os(iOS)
        let showAccessCellIdentifier = "ShowAccessCell"
        collectionView.register(HostCollectionViewCell<ShowAccessCell>.self, forCellWithReuseIdentifier: showAccessCellIdentifier)
        #else
        let featuredMediaCellIdentifier = "FeaturedMediaCell"
        collectionView.register(HostCollectionViewCell<FeaturedMediaCell>.self, forCellWithReuseIdentifier: featuredMediaCellIdentifier)
        
        let featuredShowCellIdentifier = "FeaturedShowCell"
        collectionView.register(HostCollectionViewCell<FeaturedShowCell>.self, forCellWithReuseIdentifier: featuredShowCellIdentifier)
        #endif
        
        // TODO: Factor out cell dequeue code per type
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            #if os(iOS)
            case let .media(media, section):
                if section.properties.presentationType == .livestreams {
                    if media.contentType == .livestream || media.contentType == .scheduledLivestream {
                        let liveMediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: liveMediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<LiveMediaCell>
                        liveMediaCell?.content = LiveMediaCell(media: media)
                        return liveMediaCell
                    }
                    else {
                        let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: mediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<MediaCell>
                        mediaCell?.content = MediaCell(media: media)
                        return mediaCell
                    }
                }
                else {
                    let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: mediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<MediaCell>
                    mediaCell?.content = MediaCell(media: media, style: .show)
                    return mediaCell
                }
            #else
            case let .media(media, section):
                if section.properties.layout == .hero {
                    let featuredMediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: featuredMediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<FeaturedMediaCell>
                    featuredMediaCell?.content = FeaturedMediaCell(media: media, layout: .hero)
                    return featuredMediaCell
                }
                else if section.properties.layout == .highlight {
                    let featuredMediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: featuredMediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<FeaturedMediaCell>
                    featuredMediaCell?.content = FeaturedMediaCell(media: media, layout: .highlighted)
                    return featuredMediaCell
                }
                else if section.properties.presentationType == .livestreams {
                    if media.contentType == .livestream || media.contentType == .scheduledLivestream {
                        let liveMediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: liveMediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<LiveMediaCell>
                        liveMediaCell?.content = LiveMediaCell(media: media)
                        return liveMediaCell
                    }
                    else {
                        let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: mediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<MediaCell>
                        mediaCell?.content = MediaCell(media: media)
                        return mediaCell
                    }
                }
                else {
                    let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: mediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<MediaCell>
                    mediaCell?.content = MediaCell(media: media, style: .show)
                    return mediaCell
                }
            #endif
            #if os(iOS)
            case .mediaPlaceholder:
                let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: mediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<MediaCell>
                mediaCell?.content = MediaCell(media: nil)
                return mediaCell
            #else
            case let .mediaPlaceholder(_, section):
                if section.properties.layout == .hero {
                    let featuredMediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: featuredMediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<FeaturedMediaCell>
                    featuredMediaCell?.content = FeaturedMediaCell(media: nil, layout: .hero)
                    return featuredMediaCell
                }
                else if section.properties.layout == .highlight {
                    let featuredMediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: featuredMediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<FeaturedMediaCell>
                    featuredMediaCell?.content = FeaturedMediaCell(media: nil, layout: .highlighted)
                    return featuredMediaCell
                }
                else {
                    let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: mediaCellIdentifier, for: indexPath) as? HostCollectionViewCell<MediaCell>
                    mediaCell?.content = MediaCell(media: nil)
                    return mediaCell
                }
            #endif
            #if os(iOS)
            case let .show(show, _):
                let showCell = collectionView.dequeueReusableCell(withReuseIdentifier: showCellIdentifier, for: indexPath) as? HostCollectionViewCell<ShowCell>
                showCell?.content = ShowCell(show: show)
                return showCell
            #else
            case let .show(show, section):
                if section.properties.layout == .hero {
                    let featuredShowCell = collectionView.dequeueReusableCell(withReuseIdentifier: featuredShowCellIdentifier, for: indexPath) as? HostCollectionViewCell<FeaturedShowCell>
                    featuredShowCell?.content = FeaturedShowCell(show: show, layout: .hero)
                    return featuredShowCell
                }
                else if section.properties.layout == .highlight {
                    let featuredShowCell = collectionView.dequeueReusableCell(withReuseIdentifier: featuredShowCellIdentifier, for: indexPath) as? HostCollectionViewCell<FeaturedShowCell>
                    featuredShowCell?.content = FeaturedShowCell(show: show, layout: .highlighted)
                    return featuredShowCell
                }
                else {
                    let showCell = collectionView.dequeueReusableCell(withReuseIdentifier: showCellIdentifier, for: indexPath) as? HostCollectionViewCell<ShowCell>
                    showCell?.content = ShowCell(show: show)
                    return showCell
                }
            #endif
            #if os(iOS)
            case .showPlaceholder:
                let showCell = collectionView.dequeueReusableCell(withReuseIdentifier: showCellIdentifier, for: indexPath) as? HostCollectionViewCell<ShowCell>
                showCell?.content = ShowCell(show: nil)
                return showCell
            #else
            case let .showPlaceholder(_, section):
                if section.properties.layout == .hero {
                    let featuredShowCell = collectionView.dequeueReusableCell(withReuseIdentifier: featuredShowCellIdentifier, for: indexPath) as? HostCollectionViewCell<FeaturedShowCell>
                    featuredShowCell?.content = FeaturedShowCell(show: nil, layout: .hero)
                    return featuredShowCell
                }
                else if section.properties.layout == .highlight {
                    let featuredShowCell = collectionView.dequeueReusableCell(withReuseIdentifier: featuredShowCellIdentifier, for: indexPath) as? HostCollectionViewCell<FeaturedShowCell>
                    featuredShowCell?.content = FeaturedShowCell(show: nil, layout: .highlighted)
                    return featuredShowCell
                }
                else {
                    let showCell = collectionView.dequeueReusableCell(withReuseIdentifier: showCellIdentifier, for: indexPath) as? HostCollectionViewCell<ShowCell>
                    showCell?.content = ShowCell(show: nil)
                    return showCell
                }
            #endif
            case let .topic(topic, _):
                let topicCell = collectionView.dequeueReusableCell(withReuseIdentifier: topicCellIdentifier, for: indexPath) as? HostCollectionViewCell<TopicCell>
                topicCell?.content = TopicCell(topic: topic)
                return topicCell
            case .topicPlaceholder:
                let topicCell = collectionView.dequeueReusableCell(withReuseIdentifier: topicCellIdentifier, for: indexPath) as? HostCollectionViewCell<TopicCell>
                topicCell?.content = TopicCell(topic: nil)
                return topicCell
            #if os(iOS)
            case let .showAccess(radioChannel, _):
                let showAccessCell = collectionView.dequeueReusableCell(withReuseIdentifier: showAccessCellIdentifier, for: indexPath) as? HostCollectionViewCell<ShowAccessCell>
                showAccessCell?.content = ShowAccessCell(radioChannel: radioChannel) { [weak self] type in
                    if let navigationController = self?.navigationController {
                        switch type {
                        case .aToZ:
                            let showsViewController = ShowsViewController(radioChannel: radioChannel, alphabeticalIndex: nil)
                            navigationController.pushViewController(showsViewController, animated: true)
                        case .date:
                            let calendarViewController = CalendarViewController(radioChannel: radioChannel, date: nil)
                            navigationController.pushViewController(calendarViewController, animated: true)
                        }
                    }
                }
                return showAccessCell
            #endif
            }
        }
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self = self, kind == UICollectionView.elementKindSectionHeader else { return nil }
            
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            let pageTitle = indexPath.section == 0 ? self.model.title : nil
            
            let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: pageSectionHeaderViewIdentifier, for: indexPath) as! HostSupplementaryView<PageSectionHeaderView>
            sectionHeaderView.content = PageSectionHeaderView(section: section, pageTitle: pageTitle)
            return sectionHeaderView
        }
        
        model.$state
            .sink { [weak self] state in
                self?.reloadData(with: state)
            }
            .store(in: &cancellables)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
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
        // Can be triggered on a background thread. Layout is updated on the main thread.
        reloadCount += 1
        DispatchQueue.global(qos: .userInteractive).async {
            self.dataSource.apply(Self.snapshot(from: state)) {
                self.collectionView.reloadEmptyDataSet()
                self.reloadCount -= 1
                
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
        return LayoutStandardCollectionViewPaddingInsets
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
                // TODO: Should the title be managed based on the PageViewController id?
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
        if reloadCount == 0 {
            if case .loading = model.state {
                return loadingImageView
            }
            else {
                return nil
            }
        }
        else {
            return loadingImageView
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        func titleString() -> String {
            if case let .failed(error: error) = model.state {
                return error.localizedDescription
            }
            else {
                return NSLocalizedString("No results", comment: "Default text displayed when no results are available");
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

extension PageViewController {
    /**
     *  A collection view applying a stronger deceleration rate to horizontally scrollable sections.
     */
    // TODO: Remove if the compositional layout API is further improved (could be added to `UICollectionViewCompositionalLayoutConfiguration`
    //       in the future).
    @available(tvOS, unavailable)
    private class DampedCollectionView: UICollectionView {
        override func didAddSubview(_ subview: UIView) {
            super.didAddSubview(subview)
            
            if let scrollView = subview as? UIScrollView {
                Self.applySettings(to: scrollView)
            }
        }
        
        static func applySettings(to scrollView: UIScrollView) {
            guard let scrollViewClass = object_getClass(scrollView) else { return }
            
            scrollView.decelerationRate = .fast
            scrollView.alwaysBounceHorizontal = true
            
            let scrollViewSubclassName = String(cString: class_getName(scrollViewClass)).appending("_IgnoreSafeArea")
            if let viewSubclass = NSClassFromString(scrollViewSubclassName) {
                object_setClass(scrollView, viewSubclass)
            }
            else {
                guard let viewClassNameUtf8 = (scrollViewSubclassName as NSString).utf8String else { return }
                guard let scrollViewSubclass = objc_allocateClassPair(scrollViewClass, viewClassNameUtf8, 0) else { return }
                
                if let decelerationRateMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.decelerationRate)) {
                    let setDecelerationRate: @convention(block) (AnyObject, UIScrollView.DecelerationRate) -> Void = { _, _ in
                        // Do nothing, only prevent value changes
                    }
                    class_addMethod(scrollViewSubclass, #selector(setter: UIScrollView.decelerationRate), imp_implementationWithBlock(setDecelerationRate), method_getTypeEncoding(decelerationRateMethod))
                }
                
                if let alwaysBounceHorizontalMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.alwaysBounceHorizontal)) {
                    let setAlwaysBounceHorizontal: @convention(block) (AnyObject, Bool) -> Void = { _, _ in
                        // Do nothing, only prevent value changes
                    }
                    class_addMethod(scrollViewSubclass, #selector(setter: UIScrollView.alwaysBounceHorizontal), imp_implementationWithBlock(setAlwaysBounceHorizontal), method_getTypeEncoding(alwaysBounceHorizontalMethod))
                }
                
                objc_registerClassPair(scrollViewSubclass)
                object_setClass(scrollView, scrollViewSubclass)
            }
        }
    }
}
