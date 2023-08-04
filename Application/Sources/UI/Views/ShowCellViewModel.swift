//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

class ShowCellViewModel: ObservableObject {
    @Published var show: SRGShow?
    @Published private(set) var isSubscribed = false
    
    init() {
#if os(iOS)
        // Drop initial value; a relevant value is first assigned when the view appears
        $show
            .dropFirst()
            .map { show in
                guard let show else {
                    return Just(false).eraseToAnyPublisher()
                }
                return UserDataPublishers.subscriptionStatusPublisher(for: show)
                    .map { $0 == .subscribed }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSubscribed)
#endif
    }
}

// MARK: Properties

extension ShowCellViewModel {
    var title: String? {
        return show?.title
    }
    
    func imageUrl(with imageVariant: SRGImageVariant) -> URL? {
        return imageVariant == .poster ? url(for: show?.posterImage, size: .small) : url(for: show?.image, size: .small)
    }
}
