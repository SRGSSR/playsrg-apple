//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct DiskInfoFooterView: View {
    @StateObject private var model = DiskInfoFooterViewModel()
    
    var body: some View {
        Text(model.formattedFreeSpace)
            .srgFont(.caption)
            .foregroundColor(.srgGrayC7)
    }
}

// MARK: Preview

struct DiskInfoFooterView_Previews: PreviewProvider {
    static var previews: some View {
        DiskInfoFooterView()
    }
}
