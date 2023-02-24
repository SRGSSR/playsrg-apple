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
    
    enum SubscribeState {
        case notFavorited
        case notSubscribed
        case subscribed
    }
    
    @Published private(set) var subscribeState = SubscribeState.notFavorited
    
    @Published var isFavoriteRemovalAlertDisplayed = false
    
    init() {
        // Drop initial values; relevant values are first assigned when the view appears
        $show
            .dropFirst()
            .map { show in
                guard let show else {
                    return Just(SubscribeState.notFavorited).eraseToAnyPublisher()
                }
#if os(iOS)
                return Publishers.CombineLatest(
                    UserDataPublishers.favoritePublisher(for: show),
                    UserDataPublishers.subscriptionStatusPublisher(for: show)
                )
                .map { isFavorite, subscriptionStatus in
                    if isFavorite {
                        if subscriptionStatus == UserDataPublishers.SubscriptionStatus.subscribed {
                            return .subscribed
                        }
                        else {
                            return .notSubscribed
                        }
                    }
                    else {
                        return .notFavorited
                    }
                }
                .eraseToAnyPublisher()
#else
                return UserDataPublishers.favoritePublisher(for: show)
                    .map { isFavorite in
                        return isFavorite ? .notSubscribed : .notFavorited
                    }
                    .eraseToAnyPublisher()
#endif
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$subscribeState)
    }
    
    var title: String? {
        return show?.title
    }
    
    var lead: String? {
        return show?.lead?.isEmpty ?? true ? show?.summary : show?.lead
    }
    
    var broadcastInformation: String? {
        return show?.broadcastInformation?.message
    }
    
    var imageUrl: URL? {
        return url(for: show?.image, size: .large)
    }
    
    var shouldDisplayFavoriteRemovalAlert: Bool {
        guard let loggedIn = SRGIdentityService.current?.isLoggedIn, loggedIn, let show else { return false }
        return FavoritesIsSubscribedToShow(show)
    }
    
    func addFavorite() {
        guard let show else { return }
        FavoritesAddShow(show)
        
        AnalyticsHiddenEvent.favorite(action: .add, source: .button, urn: show.urn).send()
        
#if os(iOS)
        Banner.showFavorite(true, forItemWithName: show.title)
#endif
    }
    
    func removeFavorite() {
        guard let show else { return }
        FavoritesRemoveShows([show])
        
        AnalyticsHiddenEvent.favorite(action: .remove, source: .button, urn: show.urn).send()
        
#if os(iOS)
        Banner.showFavorite(false, forItemWithName: show.title)
#endif
    }
    
#if os(iOS)
    var pickerSubscribeState: SubscribeState {
        get {
            return subscribeState
        }
        set {
            toggleSubscription(to: newValue)
        }
    }
    
    private func toggleSubscription(to subscribeState: SubscribeState) {
        guard let show, self.subscribeState != .notFavorited else { return }
        
        switch subscribeState {
        case .subscribed:
            if self.subscribeState != .subscribed && FavoritesToggleSubscriptionForShow(show) {
                AnalyticsHiddenEvent.subscription(action: .add, source: .button, urn: show.urn).send()
                
                Banner.showSubscription(true, forItemWithName: show.title)
            }
        case .notSubscribed:
            if self.subscribeState != .notSubscribed && FavoritesToggleSubscriptionForShow(show) {
                AnalyticsHiddenEvent.subscription(action: .add, source: .button, urn: show.urn).send()
                
                Banner.showSubscription(true, forItemWithName: show.title)
            }
        default:
            break
        }
    }
#endif
}
