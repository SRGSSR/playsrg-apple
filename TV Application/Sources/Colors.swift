//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
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
