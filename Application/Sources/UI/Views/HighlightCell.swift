//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct HighlightCell: View {
    var body: some View {
        Color.red
    }
}

// MARK: Size

final class HighlightCellSize: NSObject {
    @objc static func fullWidth(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if horizontalSizeClass == .compact {
            return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(300))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(200))
        }
    }
}

// MARK: Preview

struct HighlightCell_Previews: PreviewProvider {
    static var previews: some View {
        HighlightCell()
    }
}
