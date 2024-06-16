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
                            } else if let show = self.show {
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
        show?.title
    }

    var summary: String? {
        show?.play_summary
    }

    var broadcastInformation: String? {
        show?.broadcastInformation?.message
    }

    var favoriteIcon: ImageResource {
        isFavorite ? .favoriteFull : .favorite
    }

    var favoriteLabel: String {
        if isFavorite {
            NSLocalizedString("Favorites", comment: "Label displayed in the show view when a show has been favorited")
        } else {
            NSLocalizedString("Add to favorites", comment: "Label displayed in the show view when a show can be favorited")
        }
    }

    var shouldDisplayFavoriteRemovalAlert: Bool {
        guard let loggedIn = SRGIdentityService.current?.isLoggedIn, loggedIn, let show else { return false }
        return FavoritesIsSubscribedToShow(show)
    }

    #if os(iOS)
        var isSubscriptionPossible: Bool {
            PushService.shared != nil
        }

        var subscriptionIcon: ImageResource {
            switch subscriptionStatus {
            case .unavailable, .unsubscribed:
                .subscription
            case .subscribed:
                .subscriptionFull
            }
        }

        var subscriptionLabel: String {
            switch subscriptionStatus {
            case .unavailable, .unsubscribed:
                NSLocalizedString("Notify me", comment: "Subscription label to be notified in the show view")
            case .subscribed:
                NSLocalizedString("Notified", comment: "Subscription label when notification enabled in the show view")
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
            } else if let pushService = PushService.shared, !pushService.isEnabled {
                wouldLikeToSubscribe = true
            }
        }
    #endif
}

// MARK: Accessibility

extension ShowHeaderViewModel {
    var favoriteAccessibilityLabel: String {
        if isFavorite {
            PlaySRGAccessibilityLocalizedString("Delete from favorites", comment: "Favorite label in the show view when a show has been favorited")
        } else {
            PlaySRGAccessibilityLocalizedString("Add to favorites", comment: "Favorite label in the show view when a show can be favorited")
        }
    }

    #if os(iOS)
        var subscriptionAccessibilityLabel: String {
            switch subscriptionStatus {
            case .unavailable, .unsubscribed:
                PlaySRGAccessibilityLocalizedString("Enable notifications for show", comment: "Show subscription label")
            case .subscribed:
                PlaySRGAccessibilityLocalizedString("Disable notifications for show", comment: "Show unsubscription label")
            }
        }
    #endif
}
