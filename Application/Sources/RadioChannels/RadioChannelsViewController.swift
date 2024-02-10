//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

@objc class RadioChannelsViewController: PageContainerViewController, PlayApplicationNavigation {
    private var radioChannelName: String?
    
    // MARK: - Object lifecycle
    
    @objc init(radioChannels: [RadioChannel]) {
        assert(!radioChannels.isEmpty, "At least 1 radio channel expected")
        
        var viewControllers = [UIViewController]()
        for radioChannel in radioChannels {
            let pageViewController = PageViewController.audiosViewController(forRadioChannel: radioChannel)
            pageViewController.tabBarItem = UITabBarItem(title: radioChannel.name, image: RadioChannelLogoImage(radioChannel), tag: 0)
            viewControllers.append(pageViewController)
        }
        
        let lastOpenedRadioChannel = ApplicationSettingLastOpenedRadioChannel()
        let initialPage = lastOpenedRadioChannel != nil ? radioChannels.firstIndex(of: lastOpenedRadioChannel!) : nil
        
        super.init(viewControllers: viewControllers, initialPage: UInt(initialPage != nil ? initialPage! : NSNotFound))
        updateTitle()
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTitle()
        
        if let navigationBar = navigationController?.navigationBar {
            navigationItem.rightBarButtonItem = GoogleCastBarButtonItem(for: navigationBar)
        }
    }
    
    // MARK: - Overrides
    
    override func didDisplayViewController(_ viewController: UIViewController, animated: Bool) {
        super.didDisplayViewController(viewController, animated: animated)
        
        guard let pageViewController = viewController as? PageViewController,
              let radioChannel = pageViewController.radioChannel else { return }
        
        radioChannelName = radioChannel.name
        
        ApplicationSettingSetLastOpenedRadioChannel(radioChannel)
        
        if let navigationController = navigationController as? NavigationController {
            navigationController.update(with: radioChannel, animated: animated)
        }
        
        updateTitle()
    }
    
    // MARK: - Navigation bar
    
    private func updateTitle() {
        navigationItem.title = radioChannelName ?? NSLocalizedString("Audios", comment: "Title displayed at the top of the audio view")
    }
    
    // MARK: - PlayApplicationNavigation protocol
    
    func open(_ applicationSectionInfo: ApplicationSectionInfo) -> Bool {
        guard let radioChannel = applicationSectionInfo.radioChannel else { return false }
        
        if let radioChannelViewController = viewControllers.first(where: { ($0 as? PageViewController)?.radioChannel == radioChannel }) as? UIViewController & PlayApplicationNavigation {
            let pageIndex = viewControllers.firstIndex(of: radioChannelViewController)!
            self.switch(to: UInt(pageIndex), animated: false)
            
            return radioChannelViewController.open(applicationSectionInfo)
        }
        
        return false
    }
    
    // MARK: - Unavailable
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Designated Initializer
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}
