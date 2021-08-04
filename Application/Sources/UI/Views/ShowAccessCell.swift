//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: Contract

@objc protocol ShowAccessCellActions: AnyObject {
    func openShowAZ()
    func openShowByDate()
}

// MARK: View

/// Behavior: h-exp, v-exp
struct ShowAccessCell: View {
    var body: some View {
        ResponderChain { firstResponder in
            HStack {
                ExpandedButton(icon: "a_to_z", label: NSLocalizedString("A to Z", comment: "Short title displayed in home pages on a button."), accessibilityHint: PlaySRGAccessibilityLocalizedString("A to Z shows", comment: "Title pronounced in home pages on shows A to Z button.")) {
                    firstResponder.sendAction(#selector(ShowAccessCellActions.openShowAZ))
                }
                ExpandedButton(icon: "calendar", label: NSLocalizedString("By date", comment: "Short title displayed in home pages on a button."), accessibilityHint: PlaySRGAccessibilityLocalizedString("Shows by date", comment: "Title pronounced in home pages on shows by date button.")) {
                    firstResponder.sendAction(#selector(ShowAccessCellActions.openShowByDate))
                }
            }
        }
    }
}

// MARK: Size

final class ShowAccessCellSize: NSObject {
    @objc static func fullWidth(layoutWidth: CGFloat) -> NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(38))
    }
}

// MARK: Preview

struct ShowAccessCell_Previews: PreviewProvider {
    private static let size = ShowAccessCellSize.fullWidth(layoutWidth: 800).previewSize
    
    static var previews: some View {
        Group {
            ShowAccessCell()
                .previewLayout(.fixed(width: size.width, height: size.height))
        }
    }
}
