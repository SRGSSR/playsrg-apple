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
import SRGDataProviderModel

// MARK: View controller

final class SearchViewController: UIViewController {
    private var model = SearchViewModel()
    
    private var searchController: UISearchController!
    private var searchContainerViewController: UISearchContainerViewController!
    
#if os(iOS)
    private weak var filtersBarButtonItem: UIBarButtonItem?
#endif
    
    private var cancellables = Set<AnyCancellable>()
    
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
        
        let searchResultsViewController = SearchResultsViewController(model: model, searchViewController: self)
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
        searchBar.delegate = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        updateSearchSettingsButton()
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
    
#if os(iOS)
    private func updateSearchSettingsButton() {
        guard !ApplicationConfiguration.shared.areSearchSettingsHidden else {
            navigationItem.rightBarButtonItem = nil
            return
        }
        
        if filtersBarButtonItem == nil {
            let filtersButton = UIButton(type: .custom)
            filtersButton.addTarget(self, action: #selector(showSettings(_:)), for: .touchUpInside)
            
            if let titleLabel = filtersButton.titleLabel {
                titleLabel.font = SRGFont.font(family: .text, weight: .regular, size: 16)
                
                // Trick to avoid incorrect truncation when Bold text has been enabled in system settings
                // See https://developer.apple.com/forums/thread/125492
                titleLabel.lineBreakMode = .byClipping
            }
            filtersButton.setTitle(NSLocalizedString("Filters", comment: "Filters button title"), for: .normal)
            filtersButton.setTitleColor(.gray, for: .highlighted)
            
            // See https://stackoverflow.com/a/25559946/760435
            let inset: CGFloat = 2
            filtersButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
            filtersButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)
            filtersButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
            
            let filtersBarButtonItem = UIBarButtonItem(customView: filtersButton)
            navigationItem.rightBarButtonItem = filtersBarButtonItem
            self.filtersBarButtonItem = filtersBarButtonItem
        }
        
        if let filtersButton = filtersBarButtonItem?.customView as? UIButton {
            let image = !model.hasDefaultSettings ? UIImage(named: "filter_on") : UIImage(named: "filter_off")
            filtersButton.setImage(image, for: .normal)
        }
    }
    
    @objc private func closeKeyboard(_ sender: Any) {
        searchController.searchBar.resignFirstResponder()
    }
    
    @objc private func showSettings(_ sender: Any) {
        searchController.searchBar.resignFirstResponder()
        
        let settingsViewController = SearchSettingsViewController(query: model.query, settings: model.settings)
        settingsViewController.delegate = self
        
        let backgroundColor: UIColor? = UIDevice.current.userInterfaceIdiom == .pad ? .play_popoverGrayBackground : nil
        let navigationController = NavigationController(rootViewController: settingsViewController,
                                                        tintColor: .white,
                                                        backgroundColor: backgroundColor,
                                                        statusBarStyle: .lightContent)
        navigationController.modalPresentationStyle = .popover
        
        if let popoverPresentationController = navigationController.popoverPresentationController {
            popoverPresentationController.backgroundColor = .play_popoverGrayBackground
            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.barButtonItem = filtersBarButtonItem
        }
        
        present(navigationController, animated: true)
    }
#endif
}

// MARK: Protocols

#if os(iOS)
extension SearchViewController: PlayApplicationNavigation {
    func open(_ applicationSectionInfo: ApplicationSectionInfo) -> Bool {
        guard applicationSectionInfo.applicationSection == .search else { return false }
        
        model.query = applicationSectionInfo.options?[ApplicationSectionOptionKey.searchQueryKey] as? String ?? ""
        
        let settings = SRGMediaSearchSettings()
        if let mediaType = applicationSectionInfo.options?[ApplicationSectionOptionKey.searchMediaTypeOptionKey] as? Int {
            settings.mediaType = SRGMediaType(rawValue: mediaType) ?? .none
        }
        model.settings = settings
        
        return true
    }
}

extension SearchViewController: SearchResultsViewControllerDelegate {
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didSelectItem item: SearchViewModel.Item) {
        switch item {
        case let .media(media):
            play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
            
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.value = media.urn
            labels.type = AnalyticsType.actionPlayMedia.rawValue
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.searchOpen.rawValue, labels: labels)
        case let .show(show):
            guard let navigationController = navigationController else { return }
            
            let showViewController = SectionViewController.showViewController(for: show)
            navigationController.pushViewController(showViewController, animated: true)
            
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.value = show.urn
            labels.type = AnalyticsType.actionDisplayShow.rawValue
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.searchTeaserOpen.rawValue, labels: labels)
            
            SRGDataProvider.current!.increaseSearchResultsViewCount(for: show)
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }
}

extension SearchViewController: SearchSettingsViewControllerDelegate {
    func searchSettingsViewController(_ searchSettingsViewController: SearchSettingsViewController, didUpdate settings: SRGMediaSearchSettings) {
        model.settings = settings
        updateSearchSettingsButton()
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Cancel", comment: "Title of a cancel button"),
            style: .plain,
            target: self,
            action: #selector(closeKeyboard(_:))
        )
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        navigationItem.leftBarButtonItem = nil
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
