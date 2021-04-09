//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

struct ShowAccessCell: View {
    let radioChannel: RadioChannel?
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? TabBarController {
                    let showsViewController = ShowsViewController(radioChannel: radioChannel, alphabeticalIndex: nil)
                    tabBarController.pushViewController(showsViewController, animated: true)
                }
            } ) {
                HStack {
                    Image("atoz-22")
                    Text(NSLocalizedString("A to Z", comment: "Short title displayed in home pages on a button."))
                        .srgFont(.button2)
                }
            }
            .foregroundColor(.white)
            .accessibilityLabel(PlaySRGAccessibilityLocalizedString("A to Z shows", "Title pronounced in home pages on shows A to Z button."))
            
            Button(action: {
                if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? TabBarController {
                    let calendarViewController = CalendarViewController(radioChannel: radioChannel, date: nil)
                    tabBarController.pushViewController(calendarViewController, animated: true)
                }
            } ) {
                HStack {
                    Image("calendar-22")
                    Text(NSLocalizedString("By date", comment: "Short title displayed in home pages on a button."))
                        .srgFont(.button2)

                }
            }
            .foregroundColor(.white)
            .accessibilityLabel(PlaySRGAccessibilityLocalizedString("Shows by date", "Title pronounced in home pages on shows by date button."))
        }
        .padding()
    }
}

struct ShowAccessCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ShowAccessCell(radioChannel: nil)
                .previewLayout(.fixed(width: 375, height: 400))
                .previewDisplayName("TV show access")
        }
    }
}
