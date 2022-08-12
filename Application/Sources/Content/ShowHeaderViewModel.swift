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
    @Published private(set) var subscriptionStatus: UserDataPublishers.SubscriptionStatus = .unavailable
    
    @Published var isFavoriteRemovalAlertDisplayed = false
    
    init() {
        // Drop initial values; relevant values are first assigned when the view appears
        $show
            .dropFirst()
            .map { show -> AnyPublisher<Bool, Never> in
                guard let show = show else {
                    return Just(false).eraseToAnyPublisher()
                }
                return UserDataPublishers.favoritePublisher(for: show)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$isFavorite)
        
#if os(iOS)
        // Drop initial values; relevant values are first assigned when the view appears
        $show
            .dropFirst()
            .map { show -> AnyPublisher<UserDataPublishers.SubscriptionStatus, Never> in
                guard let show = show else {
                    return Just(.unavailable).eraseToAnyPublisher()
                }
                return UserDataPublishers.subscriptionStatusPublisher(for: show)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$subscriptionStatus)
#endif
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
        return url(for: show?.image, size: .medium)
    }
    
    var favoriteIcon: String {
        return isFavorite ? "favorite_full" : "favorite"
    }
    
    var favoriteLabel: String {
        if isFavorite {
            return NSLocalizedString("Favorites", comment: "Label displayed in the show view when a show has been favorited")
        }
        else {
            return NSLocalizedString("Add to favorites", comment: "Label displayed in the show view when a show can be favorited")
        }
    }
    
    var shouldDisplayFavoriteRemovalAlert: Bool {
        guard let loggedIn = SRGIdentityService.current?.isLoggedIn, loggedIn, let show = show else { return false }
        return FavoritesIsSubscribedToShow(show)
    }
    
#if os(iOS)
    var isSubscriptionPossible: Bool {
        return PushService.shared != nil && isFavorite
    }
    
    var subscriptionIcon: String {
        switch subscriptionStatus {
        case .unavailable:
            return "subscription_disabled"
        case .unsubscribed:
            return "subscription"
        case .subscribed:
            return "subscription_full"
        }
    }
    
    var subscriptionLabel: String {
        switch subscriptionStatus {
        case .unavailable, .unsubscribed:
            return NSLocalizedString("Notify me", comment: "Subscription label to be notified in the show view")
        case .subscribed:
            return NSLocalizedString("Notified", comment: "Subscription label when notification enabled in the show view")
        }
    }
#endif
    
    func toggleFavorite() {
        guard let show = show else { return }
        FavoritesToggleShow(show)
        
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.source = AnalyticsSource.button.rawValue
        labels.value = show.urn
        
        let name = isFavorite ? AnalyticsTitle.favoriteRemove.rawValue : AnalyticsTitle.favoriteAdd.rawValue
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
        
#if os(iOS)
        Banner.showFavorite(!isFavorite, forItemWithName: show.title)
#endif
    }
    
#if os(iOS)
    func toggleSubscription() {
        guard let show = show, FavoritesToggleSubscriptionForShow(show) else { return }
        
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.source = AnalyticsSource.button.rawValue
        labels.value = show.urn
        
        let isSubscribed = (subscriptionStatus == .subscribed)
        let name = isSubscribed ? AnalyticsTitle.subscriptionRemove.rawValue : AnalyticsTitle.subscriptionAdd.rawValue
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
        
        Banner.showSubscription(!isSubscribed, forItemWithName: show.title)
    }
#endif
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
    
#if os(iOS)
    var subscriptionAccessibilityLabel: String {
        switch subscriptionStatus {
        case .unavailable, .unsubscribed:
            return PlaySRGAccessibilityLocalizedString("Enable notifications for show", comment: "Show subscription label")
        case .subscribed:
            return PlaySRGAccessibilityLocalizedString("Disable notifications for show", comment: "Show unsubscription label")
        }
    }
#endif
}
