//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class ShowDetailModel: ObservableObject {
    let show: SRGShow
    
    @Published private(set) var medias: [SRGMedia] = []
    
    var cancellables = Set<AnyCancellable>()
    
    init(show: SRGShow) {
        self.show = show
    }
    
    func refresh() {
        SRGDataProvider.current!.latestMediasForShows(withUrns: [show.urn])
            .map { $0.medias }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: \.medias, on: self)
            .store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
}
