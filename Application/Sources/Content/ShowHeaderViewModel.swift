//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderModel

class ShowHeaderViewModel: ObservableObject {
    var show: SRGShow? {
        didSet {
            updatePublishers()
        }
    }
    
    @Published private(set) var isFavorite: Bool = false
    @Published private(set) var isSubscribed: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    var title: String? {
        return show?.title
    }
    
    var lead: String? {
        return show?.lead
    }
    
    var imageUrl: URL? {
        return show?.imageUrl(for: .large)
    }
    
    func toggleFavorite() {
        guard let show = show else { return }
        FavoritesToggleShow(show)
        updateData()
    }
    
    #if os(iOS)
    func toggleSubscription() {
        guard let show = show else { return }
        FavoritesToggleSubscriptionForShow(show)
        updateData()
    }
    #endif
    
    private func updatePublishers() {
        cancellables = []
        
        Publishers.Merge(Signal.favoritesUpdate(), Signal.wokenUp())
            .sink { [weak self] _ in
                self?.updateData()
            }
            .store(in: &cancellables)
        updateData()
    }
    
    private func updateData() {
        if let show = show {
            isFavorite = FavoritesContainsShow(show)
            isSubscribed = FavoritesIsSubscribedToShow(show)
        }
        else {
            isFavorite = false
            isSubscribed = false
        }
    }
}
