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
                Button {
                    firstResponder.sendAction(#selector(ShowAccessCellActions.openShowAZ))
                } label: {
                    HStack {
                        Image("atoz-22")
                        Text(NSLocalizedString("A to Z", comment: "Short title displayed in home pages on a button."))
                            .srgFont(.button)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.srgGray2)
                    .cornerRadius(LayoutStandardViewCornerRadius)
                }
                .foregroundColor(.srgGray5)
                .accessibilityElement(label: PlaySRGAccessibilityLocalizedString("A to Z shows", "Title pronounced in home pages on shows A to Z button."))
                
                Button {
                    firstResponder.sendAction(#selector(ShowAccessCellActions.openShowByDate))
                } label: {
                    HStack {
                        Image("calendar-22")
                        Text(NSLocalizedString("By date", comment: "Short title displayed in home pages on a button."))
                            .srgFont(.button)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.srgGray2)
                    .cornerRadius(LayoutStandardViewCornerRadius)
                }
                .foregroundColor(.srgGray5)
                .accessibilityElement(label: PlaySRGAccessibilityLocalizedString("Shows by date", "Title pronounced in home pages on shows by date button."))
            }
        }
    }
}

// MARK: Size

class ShowAccessCellSize: NSObject {
    @objc static func fullWidth(layoutWidth: CGFloat) -> NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(38))
    }
}

// MARK: Preview

struct ShowAccessCell_Previews: PreviewProvider {
    static let size = ShowAccessCellSize.fullWidth(layoutWidth: 800).previewSize
    
    static var previews: some View {
        Group {
            ShowAccessCell()
                .previewLayout(.fixed(width: size.width, height: size.height))
        }
    }
}
