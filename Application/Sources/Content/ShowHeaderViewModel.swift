//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderModel
import SRGIdentity

// MARK: View model

final class ShowHeaderViewModel: ObservableObject {
    @Published var show: SRGShow?
    
    @Published private(set) var isFavorite = false
    
    @Published var isFavoriteRemovalAlertDisplayed = false
    
    init() {
        // Drop initial values; relevant values are first assigned when the view appears
        $show
            .dropFirst()
            .map { show in
                guard let show else {
                    return Just(false).eraseToAnyPublisher()
                }
                return UserDataPublishers.favoritePublisher(for: show)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$isFavorite)
    }
    
    var title: String? {
        return show?.title
    }
    
    var lead: String? {
        return show?.lead
    }
    
    var broadcastInformation: String? {
        return show?.broadcastInformation?.message
    }
    
    var imageUrl: URL? {
        return url(for: show?.image, size: .large)
    }
    
    var favoriteIcon: String {
        return isFavorite ? "favorite_full" : "favorite"
    }
    
    var favoriteLabel: String {
        return NSLocalizedString("Favorites", comment: "Label displayed in the show view")
    }
    
    var shouldDisplayFavoriteRemovalAlert: Bool {
        guard let loggedIn = SRGIdentityService.current?.isLoggedIn, loggedIn, let show else { return false }
        return FavoritesIsSubscribedToShow(show)
    }
    
    func toggleFavorite() {
        guard let show else { return }
        FavoritesToggleShow(show)
        
        let action = isFavorite ? .remove : .add as AnalyticsListAction
        AnalyticsHiddenEvent.favorite(action: action, source: .button, urn: show.urn).send()
        
#if os(iOS)
        Banner.showFavorite(!isFavorite, forItemWithName: show.title)
#endif
    }
}

// MARK: Accessibility

extension ShowHeaderViewModel {
    var favoriteAccessibilityLabel: String {
        if isFavorite {
            return PlaySRGAccessibilityLocalizedString("Delete from favorites", comment: "Favorite label in the show view when a show has been favorited")
        }
        else {
            return PlaySRGAccessibilityLocalizedString("Add to favorites", comment: "Favorite label in the show view when a show can be favorited")
        }
    }
}
