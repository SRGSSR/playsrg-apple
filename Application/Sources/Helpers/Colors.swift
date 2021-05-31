//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

extension Color {
    public static let darkGray = Color(.darkGray)
}

#if DEBUG
extension UIColor {
    public static func random(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: alpha)
    }
}
#endif
