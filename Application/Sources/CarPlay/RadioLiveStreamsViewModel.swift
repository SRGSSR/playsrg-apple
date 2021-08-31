//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

// MARK: - View Model

final class RadioLiveStreamsViewModel: ObservableObject {
    @Published private(set) var medias: [SRGMedia] = []

    init() {
        SRGDataProvider.current!
            .radioLivestreams(for: ApplicationConfiguration.shared.vendor, contentProviders: .all)
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &$medias)
    }
}
