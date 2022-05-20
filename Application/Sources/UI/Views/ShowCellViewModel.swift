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
#if os(iOS)
        if let isEnabled = PushService.shared?.isEnabled, isEnabled, let show = show {
            isSubscribed = FavoritesIsSubscribedToShow(show)
        }
        else {
            isSubscribed = false
        }
#else
        isSubscribed = false
#endif
    }
}

// MARK: Properties

extension ShowCellViewModel {
    var title: String? {
        return show?.title
    }
    
    func imageUrl(with imageVariant: SRGImageVariant) -> URL? {
        return imageVariant == .poster ? url(for: show?.posterImage, size: .small, scaling: .preserveAspectRatio) : url(for: show?.image, size: .small)
    }
}
