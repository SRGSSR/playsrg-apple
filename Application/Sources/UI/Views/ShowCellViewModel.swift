//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

class ShowCellViewModel: ObservableObject {
    @Published var show: SRGShow? {
        didSet {
            updatePublishers()
        }
    }
    
    @Published private(set) var isSubscribed: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
        
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
        if let isEnabled = PushService.shared?.isEnabled, isEnabled, let show = show {
            isSubscribed = FavoritesIsSubscribedToShow(show)
        }
        else {
            isSubscribed = false
        }
    }
}

// MARK: Properties

extension ShowCellViewModel {
    var title: String? {
        return show?.title
    }
    
    var imageUrl: URL? {
        return show?.imageUrl(for: .small)
    }
}
