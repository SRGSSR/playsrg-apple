//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct DownloadCell: View {
    enum Layout {
        case vertical
        case horizontal
        case adaptive
    }
    
    let download: Download?
    let layout: Layout
    
    @Environment(\.isEditing) private var isEditing
    @Environment(\.isSelected) private var isSelected
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var direction: StackDirection {
        if layout == .horizontal || (layout == .adaptive && horizontalSizeClass == .compact) {
            return .horizontal
        }
        else {
            return .vertical
        }
    }
    
    private var title: String {
        return download?.title ?? .placeholder(length: 10)
    }
    
    private var size: String? {
        guard let size = download?.size else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    init(download: Download?, layout: Layout = .adaptive) {
        self.download = download
        self.layout = layout
    }
    
    var body: some View {
        Stack(direction: direction) {
            Text(title)
            if let size = size {
                Text(size)
            }
        }
    }
}

// MARK: Preview

struct DownloadCell_Previews: PreviewProvider {
    // TODO: We should be able to mock downloads
    static var previews: some View {
        DownloadCell(download: nil, layout: .vertical)
        DownloadCell(download: nil, layout: .horizontal)
    }
}
