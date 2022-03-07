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
    
    @Binding private(set) var download: Download?
    @StateObject private var model = DownloadCellViewModel()
    
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
    
    init(download: Download?, layout: Layout = .adaptive) {
        _download = .constant(download)
        self.layout = layout
    }
    
    var body: some View {
        Stack(direction: direction) {
            Text(model.title)
            if let size = model.size {
                Text(size)
            }
        }
        .onAppear {
            model.download = download
        }
        .onChange(of: download) { newValue in
            model.download = newValue
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
