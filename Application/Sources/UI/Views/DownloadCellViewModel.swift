//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class DownloadCellViewModel: ObservableObject {
    @Published var download: Download?
    
    var title: String {
        return download?.title ?? .placeholder(length: 10)
    }
    
    var size: String? {
        guard let size = download?.size else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var imageUrl: URL? {
        return download?.media?.imageUrl(for: .small) ?? download?.imageUrl(for: .small)
    }
}
