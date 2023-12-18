//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

@objc class GradientView: UIView {
    private var gradientLayer: CAGradientLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }
    
    @objc func updateWithStartColor(_ startColor: UIColor?, at startPoint: CGPoint, endColor: UIColor?, at endPoint: CGPoint, animated: Bool) {
        let update: () -> Void = {
            let fromColor = startColor ?? self.backgroundColor ?? .clear
            let toColor = endColor ?? self.backgroundColor ?? .clear
            
            self.gradientLayer.colors = [fromColor.cgColor, toColor.cgColor]
            self.gradientLayer.startPoint = startPoint
            self.gradientLayer.endPoint = endPoint
        }
        
        if animated {
            update()
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            update()
            CATransaction.commit()
        }
    }
    
    private func commonInit() {
        gradientLayer = CAGradientLayer()
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
