//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

@objc protocol ShowAccessCellActions: AnyObject {
    func openShowAZ()
    func openShowByDate()
}

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
                            .srgFont(.body)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(LayoutStandardViewCornerRadius)
                }
                .foregroundColor(.white)
                .accessibilityLabel(PlaySRGAccessibilityLocalizedString("A to Z shows", "Title pronounced in home pages on shows A to Z button."))
                
                Button {
                    firstResponder.sendAction(#selector(ShowAccessCellActions.openShowByDate))
                } label: {
                    HStack {
                        Image("calendar-22")
                        Text(NSLocalizedString("By date", comment: "Short title displayed in home pages on a button."))
                            .srgFont(.body)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(LayoutStandardViewCornerRadius)
                }
                .foregroundColor(.white)
                .accessibilityLabel(PlaySRGAccessibilityLocalizedString("Shows by date", "Title pronounced in home pages on shows by date button."))
            }
        }
    }
}

class ShowAccessCellSize: NSObject {
    @objc static func fullWidth(layoutWidth: CGFloat) -> CGSize {
        return CGSize(width: layoutWidth, height: 38)
    }
}

struct ShowAccessCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ShowAccessCell()
                .previewLayout(.fixed(width: 375, height: 38))
        }
    }
}
