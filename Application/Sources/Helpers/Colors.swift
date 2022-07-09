//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

extension Color {
    public static let darkGray = Color(.darkGray)
    public static let placeholder = Color(.placeholder)
}

extension UIColor {
    func image(ofSize size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { context in
            self.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    public static var placeholder = UIColor(white: 1, alpha: 0.1)
    
#if DEBUG
    public static func random(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: alpha)
    }
#endif
}
