//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance

extension UIColor {
    @objc static var play_black80a: UIColor {
        .black.withAlphaComponent(0.8)
    }

    @objc static var play_notificationRed: UIColor {
        play_hexadecimal("#ed3323")
    }

    @objc static var play_orange: UIColor {
        play_hexadecimal("#df5200")
    }

    static var play_popoverGrayBackground: UIColor {
        if UIDevice.current.userInterfaceIdiom == .pad {
            play_hexadecimal("#2d2d2d")
        } else {
            play_hexadecimal("#1a1a1a")
        }
    }

    @objc static var play_blackDurationLabelBackground: UIColor {
        UIColor(white: 0.0, alpha: 0.5)
    }

    private static func play_hexadecimal(_ string: String) -> UIColor {
        UIColor.hexadecimal(string) ?? UIColor.white
    }
}
