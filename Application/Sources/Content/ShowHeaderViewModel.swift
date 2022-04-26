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
    var show: SRGShow? {
        didSet {
            updatePublishers()
        }
    }
    
    @Published private(set) var isFavorite: Bool = false
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unavailable
    
    @Published var isFavoriteRemovalAlertDisplayed: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
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
    
    private static func subscriptionStatus(for show: SRGShow?) -> SubscriptionStatus {
#if os(iOS)
        if let isEnabled = PushService.shared?.isEnabled, isEnabled, let show = show {
            return FavoritesIsSubscribedToShow(show) ? .subscribed : .unsubscribed
        }
        else {
            return .unavailable
        }
#else
        return .unavailable
#endif
    }
    
    func toggleFavorite() {
        guard let show = show else { return }
        FavoritesToggleShow(show)
        updateData()
        
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.source = AnalyticsSource.button.rawValue
        labels.value = show.urn
        
        let name = isFavorite ? AnalyticsTitle.favoriteAdd.rawValue : AnalyticsTitle.favoriteRemove.rawValue
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
        
#if os(iOS)
        Banner.showFavorite(isFavorite, forItemWithName: show.title)
#endif
    }
    
#if os(iOS)
    func toggleSubscription() {
        guard let show = show, FavoritesToggleSubscriptionForShow(show) else { return }
        updateData()
        
        let isSubscribed = FavoritesIsSubscribedToShow(show)
        subscriptionStatus = isSubscribed ? .subscribed : .unsubscribed
        
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.source = AnalyticsSource.button.rawValue
        labels.value = show.urn
        
        let name = isSubscribed ? AnalyticsTitle.subscriptionAdd.rawValue : AnalyticsTitle.subscriptionRemove.rawValue
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
        
        Banner.showSubscription(isSubscribed, forItemWithName: show.title)
    }
#endif
    
    private func updatePublishers() {
        cancellables = []
        
        Publishers.Merge(ThrottledSignal.preferenceUpdates(), ApplicationSignal.pushServiceStatusUpdate())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateData()
            }
            .store(in: &cancellables)
        updateData()
    }
    
    private func updateData() {
        if let show = show {
            isFavorite = FavoritesContainsShow(show)
        }
        else {
            isFavorite = false
        }
        subscriptionStatus = Self.subscriptionStatus(for: show)
    }
}

// MARK: Types

extension ShowHeaderViewModel {
    enum SubscriptionStatus {
        case unavailable
        case unsubscribed
        case subscribed
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
