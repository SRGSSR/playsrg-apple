//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class DownloadCellViewModel: ObservableObject {
    @Published var download: Download?
    
    var title: String? {
        return download?.title
    }
    
    var size: String? {
        guard let size = download?.size else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
