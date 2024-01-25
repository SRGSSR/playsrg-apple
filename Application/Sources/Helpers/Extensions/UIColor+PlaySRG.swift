//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance

extension UIColor {
    @objc static var play_notificationRed: UIColor {
        return play_hexadecimal("#ed3323")
    }
    
    @objc static var play_orange: UIColor {
        return play_hexadecimal("#df5200")
    }
    
    static var play_popoverGrayBackground: UIColor {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return play_hexadecimal("#2d2d2d")
        } else {
            return play_hexadecimal("#1a1a1a")
        }
    }
    
    @objc static var play_grayThumbnailImageViewBackground: UIColor {
        return play_hexadecimal("#202020")
    }
    
    @objc static var play_blackDurationLabelBackground: UIColor {
        return UIColor(white: 0.0, alpha: 0.5)
    }
    
    private static func play_hexadecimal(_ string: String) -> UIColor {
        return UIColor.hexadecimal(string) ?? UIColor.white
    }
}
