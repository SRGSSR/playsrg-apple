//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class DiskInfoFooterViewModel: ObservableObject {
    @Published private var freeByteCount: Int64 = 0
    
    var formattedFreeSpace: String {
        let formattedByteCount = ByteCountFormatter.string(fromByteCount: freeByteCount, countStyle: .file)
        return String(format: NSLocalizedString("Free space: %@", comment: "Total free space size, display at the bottom of download list"), formattedByteCount)
    }
    
    init() {
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .map { _ in }
            .prepend(())
            .compactMap {
                guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
                      let freeByteCount = attributes[FileAttributeKey.systemFreeSize] as? Int64 else { return nil }
                return freeByteCount
            }
            .assign(to: &$freeByteCount)
    }
}
