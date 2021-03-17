//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import UIKit

class ContentPageViewController: BaseViewController {
    let model: ContentPageModel
    
    init(id: ContentPageModel.Id) {
        self.model = ContentPageModel(id: id)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .play_black
        self.view = view
    }
}

extension ContentPageViewController: UICollectionViewDelegate {
    
}
