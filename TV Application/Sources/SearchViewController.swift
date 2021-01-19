//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAnalytics
import SwiftUI
import UIKit

class SearchViewController: UIViewController {
    private var model = SearchResultsModel()
    
    private let searchController: UISearchController
    private let searchContainerViewController: UISearchContainerViewController
    
    init() {
        let searchResultsView = SearchResultsView(model: model)
        let searchResultsViewController = UIHostingController(rootView: searchResultsView)
        searchController = UISearchController(searchResultsController: searchResultsViewController)
        
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
        model.query = searchController.searchBar.text ?? ""
    }
}

extension SearchViewController: SRGAnalyticsViewTracking {
    var srg_pageViewTitle: String {
        return AnalyticsPageTitle.home.rawValue
    }
    
    var srg_pageViewLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.search.rawValue]
    }
}
