//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UIVisualEffectView {
    /**
     *  Standard view with blur effect consistent with Play look and feel.
     */
    @objc static var play_blurView: UIVisualEffectView {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
        blurView.backgroundColor = nil
        return blurView
    }
}
