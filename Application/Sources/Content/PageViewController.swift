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
    
    @objc static func videosViewController() -> UIViewController {
        return PageViewController(id: .video)
    }
    
    @objc static func audiosViewController(forRadioChannel channel: RadioChannel) -> UIViewController {
        return PageViewController(id: .audio(channel: channel))
    }
    
    @objc static func liveViewController() -> UIViewController {
        return PageViewController(id: .live)
    }
    
    private static func layout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(160), heightDimension: .absolute(90))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 40
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
        
        let refreshControl = RefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.insertSubview(refreshControl, at: 0)
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.$rows.sink { rows in
            self.reloadData(withRows: rows)
        }
        .store(in: &cancellables)
    }
    
    override func refresh() {
        model.refresh()
    }
    
    func reloadData(withRows rows: [PageModel.Row]) {
        print("--> Change triggered a reload")
    }
    
    @objc func pullToRefresh(_ sender: RefreshControl) {
        refresh()
    }
}

extension PageViewController: UICollectionViewDelegate {
    
}

// TODO: Remaining protocols to implement, as was the case for HomeViewController

#if false

extension PageViewController: ContentInsets {
    
}

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
