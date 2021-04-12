//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

struct ShowAccessCell: View {
    enum ButtonType {
        case aToZ
        case date
    }
    
    let radioChannel: RadioChannel?
    let action: (ButtonType) -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: { action(.aToZ) }) {
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
            
            Button(action: { action(.date) }) {
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
        .frame(height: 38)
    }
}

struct ShowAccessCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ShowAccessCell(radioChannel: nil, action: { _ in })
                .previewLayout(.fixed(width: 375, height: 400))
                .previewDisplayName("TV show access")
        }
    }
}
