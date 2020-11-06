//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class ShowDetailModel: ObservableObject {
    let show: SRGShow
    
    typealias Row = CollectionRow<Section, SRGMedia>
    
    @Published private(set) var rows: [Row] = []
    
    var cancellables = Set<AnyCancellable>()
    
    init(show: SRGShow) {
        self.show = show
    }
    
    func refresh() {
        SRGDataProvider.current!.latestMediasForShows(withUrns: [show.urn], pageSize: ApplicationConfiguration.shared.pageSize)
            .map { result in
                return [Row(section: .main, items: result.medias)]
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: \.rows, on: self)
            .store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
}

extension ShowDetailModel {
    enum Section: Hashable {
        case main
    }
}
