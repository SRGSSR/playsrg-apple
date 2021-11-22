//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAnalytics
import SRGAppearanceSwift
import SwiftUI
import UIKit

// MARK: View controller

final class SearchViewController: UIViewController {
    private var model = SearchViewModel()
    
    private var searchController: UISearchController!
    private var searchContainerViewController: UISearchContainerViewController!
    
#if os(tvOS)
    private var cancellables = Set<AnyCancellable>()
#endif
    
    init() {
        super.init(nibName: nil, bundle: nil)
        title = TitleForApplicationSection(.search)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchResultsViewController = SearchResultsViewController(model: model)
#if os(iOS)
        searchResultsViewController.delegate = self
#endif
        
        searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        
#if os(iOS)
        searchController.showsSearchResultsController = true
        
        let searchBar = searchController.searchBar
        object_setClass(searchBar, SearchBar.self)
        
        searchBar.placeholder = NSLocalizedString("Search", comment: "Search placeholder text")
        searchBar.autocapitalizationType = .none
        searchBar.tintColor = .white
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
#endif
        
        searchContainerViewController = UISearchContainerViewController(searchController: searchController)
        addChild(searchContainerViewController)
        searchContainerViewController.view.frame = view.bounds
        view.addSubview(searchContainerViewController.view)
        searchContainerViewController.didMove(toParent: self)
        
        // Required for proper search bar behavior
        definesPresentationContext = true
        
#if os(tvOS)
        model.$state
            .sink { state in
                if case let .loaded(rows: _, suggestions: suggestions) = state {
                    if let suggestions = suggestions {
                        self.searchController.searchSuggestions = suggestions.map { UISearchSuggestionItem(localizedSuggestion: $0.text) }
                    }
                    else {
                        self.searchController.searchSuggestions = nil
                    }
                }
                else {
                    self.searchController.searchSuggestions = nil
                }
            }
            .store(in: &cancellables)
#endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.reload()
        searchController.searchResultsController?.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.searchResultsController?.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.searchResultsController?.viewWillDisappear(animated)
#if os (iOS)
        if play_isMovingFromParentViewController() {
            searchController.searchBar.resignFirstResponder()
        }
#endif
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        searchController.searchResultsController?.viewDidDisappear(animated)
        
        if play_isMovingFromParentViewController() {
            // Dismiss to avoid retain cycle if the search was entered once, see https://stackoverflow.com/a/33619501/760435
            searchController.dismiss(animated: false, completion: nil)
        }
    }
}

// MARK: Protocols

#if os(iOS)
extension SearchViewController: SearchResultsViewControllerDelegate {
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didSelectItem item: SearchViewModel.Item) {
        switch item {
        case let .media(media):
            play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
        case let .show(show):
            if let navigationController = navigationController {
                let showViewController = SectionViewController.showViewController(for: show)
                navigationController.pushViewController(showViewController, animated: true)
            }
        }
    }
}
#endif

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
