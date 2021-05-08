//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

class SectionDetailViewController: DataViewController {

    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .play_black
        
        let label = UILabel(frame: view.bounds)
        label.text = "Section detail"
        label.textAlignment = .center
        view.addSubview(label)
        
        self.view = view
    }
}

// TODO: Remaining protocols to implement

#if false

extension PageViewController: PlayApplicationNavigation {
    
}

extension PageViewController: SRGAnalyticsViewTracking {
    
}

#endif
