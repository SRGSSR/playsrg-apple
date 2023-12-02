//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

class RefreshControl: UIRefreshControl {
    override init() {
        super.init()
        
        tintColor = UIColor.white
        layer.zPosition = -1.0 // Ensure the refresh control appears behind the cells
        isUserInteractionEnabled = false // Avoid conflicts with table view cell interactions when using VoiceOver
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
