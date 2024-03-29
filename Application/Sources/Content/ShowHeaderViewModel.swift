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
    
    private var wouldLikeToSubscribe = false
    
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
#if os(iOS)
        // Drop initial values; relevant values are first assigned when the view appears
        $show
            .dropFirst()
            .map { show in
                guard let show else {
                    return Just(UserDataPublishers.SubscriptionStatus.unavailable).eraseToAnyPublisher()
                }
                return UserDataPublishers.subscriptionStatusPublisher(for: show)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .map { subscriptionStatus in
                if self.wouldLikeToSubscribe {
                    if let pushService = PushService.shared, pushService.isEnabled {
                        if subscriptionStatus != .subscribed {
                            self.toggleSubscription()
                        }
                        else if let show = self.show {
                            Banner.showSubscription(true, forItemWithName: show.title)
                        }
                        self.wouldLikeToSubscribe = false
                    }
                }
                return subscriptionStatus
            }
            .assign(to: &$subscriptionStatus)
#endif
    }
    
    var title: String? {
        return show?.title
    }
    
    var summary: String? {
        return show?.play_summary
    }
    
    var broadcastInformation: String? {
        return show?.broadcastInformation?.message
    }
    
    var imageUrl: URL? {
        return url(for: show?.image, size: .large)
    }
    
    var favoriteIcon: ImageResource {
        return isFavorite ? .favoriteFull : .favorite
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
        guard let loggedIn = SRGIdentityService.current?.isLoggedIn, loggedIn, let show else { return false }
        return FavoritesIsSubscribedToShow(show)
    }
    
#if os(iOS)
    var isSubscriptionPossible: Bool {
        return PushService.shared != nil
    }
    
    var subscriptionIcon: ImageResource {
        switch subscriptionStatus {
        case .unavailable, .unsubscribed:
            return .subscription
        case .subscribed:
            return .subscriptionFull
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
        guard let show else { return }
        FavoritesToggleShow(show)
        
        let action = isFavorite ? .remove : .add as AnalyticsListAction
        AnalyticsEvent.favorite(action: action, source: .button, urn: show.urn).send()
        
#if os(iOS)
        Banner.showFavorite(!isFavorite, forItemWithName: show.title)
#endif
    }
    
#if os(iOS)
    func toggleSubscription() {
        guard let show else { return }
        
        if FavoritesToggleSubscriptionForShow(show) {
            let isSubscribed = (subscriptionStatus == .subscribed)
            let action = isSubscribed ? .remove : .add as AnalyticsListAction
            AnalyticsEvent.subscription(action: action, source: .button, urn: show.urn).send()
            
            Banner.showSubscription(!isSubscribed, forItemWithName: show.title)
        }
        else if let pushService = PushService.shared, !pushService.isEnabled {
            wouldLikeToSubscribe = true
        }
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
