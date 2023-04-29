//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct HelpButton: View {
    static var height: CGFloat {
        return 38
    }
    
    var body: some View {
        ExpandingButton(icon: "help", label: NSLocalizedString("Help and contact", comment: "Help and contact button title")) {
            if let topViewViewController = UIApplication.shared.mainTopViewController {
                topViewViewController.present(HelpNavigationViewController.viewController(), animated: true)
            }
        }
    }
}

// MARK: Preview

struct HelpButton_Previews: PreviewProvider {
    private static let size = CGSize(width: 320, height: HelpButton.height)
    static var previews: some View {
        HelpButton()
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
