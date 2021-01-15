//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

// TODO: Turn into a UIHostingController
// TODO: Somehow make searchController.searchControllerObservedScrollView = scrollView possible for SwiftUI views
class SearchResultsViewController: UIViewController {
    override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .white
    }
}

class SearchViewController: UIViewController {
    private let searchController: UISearchController
    private let searchContainerViewController: UISearchContainerViewController
    
    init() {
        searchController = UISearchController(searchResultsController: SearchResultsViewController())
        searchContainerViewController = UISearchContainerViewController(searchController: searchController)
        super.init(nibName: nil, bundle: nil)
        
        searchController.searchResultsUpdater = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(searchContainerViewController)
        searchContainerViewController.view.frame = view.bounds
        view.addSubview(searchContainerViewController.view)
        searchContainerViewController.didMove(toParent: self)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
    }
}
