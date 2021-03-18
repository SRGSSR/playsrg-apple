//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import UIKit

class PageViewController: BaseViewController {
    let model: PageModel
    
    @objc static func videosViewController() -> UIViewController {
        return PageViewController(id: .video)
    }
    
    @objc static func audiosViewController(forRadioChannel channel: RadioChannel) -> UIViewController {
        return PageViewController(id: .audio(channel: channel))
    }
    
    @objc static func liveViewController() -> UIViewController {
        return PageViewController(id: .live)
    }
    
    init(id: PageModel.Id) {
        self.model = PageModel(id: id)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc var radioChannel: RadioChannel? {
        if case let .audio(channel: channel) = model.id {
            return channel
        }
        else {
            return nil
        }
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .play_black
        self.view = view
    }
}

#if false

extension PageViewController: ContentInsets {
    
}

extension PageViewController: DZNEmptyDataSetSource {
    
}

extension PageViewController: DZNEmptyDataSetDelegate {
    
}

extension PageViewController: PlayApplicationNavigation {
    
}

extension PageViewController: SRGAnalyticsViewTracking {
    
}

extension PageViewController: TabBarActionable {
    
}

extension PageViewController: UICollectionViewDelegate {
    
}

#endif
