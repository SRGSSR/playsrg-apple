//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import GoogleCast
import SRGAppearanceSwift

/**
 *  A floating Google Cast button with intrinsic size constraints.
 */
final class GoogleCastFloatingButton: GCKUICastButton {
    private static let side: CGFloat = 44
    private static let margin: CGFloat = 2
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
    }
    
    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
        layout()
    }
    
    private func layout() {
        tintColor = .white
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.side),
            heightAnchor.constraint(equalToConstant: Self.side)
        ])
        
        let backgroundSide = Self.side - 2 * Self.margin
        assert(backgroundSide > 0, "Cast button layout parameters are incorrect")
        
        let backgroundLayer = CALayer()
        backgroundLayer.frame = CGRect(x: Self.margin, y: Self.margin, width: backgroundSide, height: backgroundSide)
        backgroundLayer.backgroundColor = UIColor.srgGray23.cgColor
        backgroundLayer.shadowOpacity = 0.7
        backgroundLayer.shadowOffset = CGSize(width: 0, height: 3)
        backgroundLayer.shadowRadius = 4
        backgroundLayer.cornerRadius = backgroundSide / 2
        layer.insertSublayer(backgroundLayer, at: 0)
    }
}
