//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

// MARK: - View Model

final class RadiosViewModel: ObservableObject {
    @Published private(set) var medias: [SRGMedia] = []
    
    init(with contentProvider: SRGContentProviders = .all) {
        SRGDataProvider.current!
            .radioLivestreams(for: ApplicationConfiguration.shared.vendor, contentProviders: contentProvider)
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &$medias)
    }
}
