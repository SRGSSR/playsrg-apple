//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SwiftUI
import UIKit

class SearchViewController: UIViewController {
    private var model = SearchResultsModel()
    
    private let searchController: UISearchController
    private let searchContainerViewController: UISearchContainerViewController
    
    @Published private var query: String = ""
    
    var cancellables = Set<AnyCancellable>()
    
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
        
        $query
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .assign(to: \.query, on: model)
            .store(in: &cancellables)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        query = searchController.searchBar.text ?? ""
    }
}
