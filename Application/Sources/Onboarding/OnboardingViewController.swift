//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import PaperOnboarding
import SRGAppearance

@objc(OnboardingViewController) public class OnboardingViewController: BaseViewController {
    final var onboarding: Onboarding!
    
    private weak var paperOnboarding: PaperOnboarding!
    
    @IBOutlet private weak var previousButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    
    @IBOutlet private weak var buttonBottomConstraint: NSLayoutConstraint!
    
    private var isTall: Bool {
        return view.frame.height >= 600.0
    }
    
    // MARK: Object lifecycle
    
    @objc public static func viewController(for onboarding: Onboarding!) -> OnboardingViewController {
        let storyboard = UIStoryboard(name: "OnboardingViewController", bundle: nil)
        let viewController = storyboard.instantiateInitialViewController() as! OnboardingViewController
        viewController.onboarding = onboarding
        viewController.title = onboarding.title
        return viewController
    }
    
    // MARK: View lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        previousButton.setTitleColor(.white, for: .normal)
        previousButton.setTitle(NSLocalizedString("Previous", comment: "Title of the button to proceed to the previous onboarding page"), for: .normal)
        
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.setTitle(NSLocalizedString("OK", comment: "Title of the button displayed at the end of an onboarding"), for: .normal)
        
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.setTitle(NSLocalizedString("Next", comment: "Title of the button to proceed to the next onboarding page"), for: .normal)
        
        // Set tint color to white. Cannot easily customize colors on a page basis (page control current item color
        // cannot be customized). Force the text to be white.
        let paperOnboarding = PaperOnboarding()
        paperOnboarding.tintColor = .white
        
        // Set the delegate before the data source so that all delegate methods are correctly called when loading the
        // first page (sigh).
        paperOnboarding.delegate = self
        paperOnboarding.dataSource = self
        view.insertSubview(paperOnboarding, at: 0)
        self.paperOnboarding = paperOnboarding
        
        NSLayoutConstraint.activate([
            paperOnboarding.topAnchor.constraint(equalTo: view.topAnchor),
            paperOnboarding.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            paperOnboarding.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paperOnboarding.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        updateUserInterface(index: 0, animated: false)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(accessibilityVoiceOverStatusChanged(notification:)),
                                               name: UIAccessibility.voiceOverStatusDidChangeNotification,
                                               object: nil)
    }
    
    // MARK: Rotation
    
    public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    // MARK: Status bar
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Overrides
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let smallFontSize = CGFloat(isTall ? 20.0 : 14.0)
        let largeFontSize = CGFloat(isTall ? 24.0 : 16.0)
        
        previousButton.titleLabel?.font = SRGFont.font(family: .text, weight: .medium, fixedSize: smallFontSize)
        closeButton.titleLabel?.font = SRGFont.font(family: .text, weight: .medium, fixedSize: largeFontSize)
        nextButton.titleLabel?.font = SRGFont.font(family: .text, weight: .medium, fixedSize: smallFontSize)
        
        buttonBottomConstraint.constant = 0.19 * view.frame.height
    }
    
    // MARK: User interface
    
    private func updateUserInterface(index: Int, animated: Bool) {
        let animations = {
            let isFirstPage = (index == 0)
            let isLastPage = (index == self.onboarding.pages.count - 1)
            
            self.closeButton.alpha = isLastPage ? 1.0 : 0.0
            
            let voiceOverEnabled = UIAccessibility.isVoiceOverRunning
            self.previousButton.alpha = (voiceOverEnabled && !isFirstPage) ? 1.0 : 0.0
            self.nextButton.alpha = (voiceOverEnabled && !isLastPage) ? 1.0 : 0.0
        }
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: animations)
        }
        else {
            animations()
        }
    }
    
    // MARK: Actions
    
    @IBAction private func previousPage(_ sender: UIButton) {
        paperOnboarding.currentIndex(paperOnboarding.currentIndex - 1, animated: true)
    }
    
    @IBAction private func close(_ sender: UIButton) {
        if ["favorites", "favorites_account"].contains(onboarding.uid) {
            PushService.shared?.presentSystemAlertForPushNotifications()
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func nextPage(_ sender: UIButton) {
        paperOnboarding.currentIndex(paperOnboarding.currentIndex + 1, animated: true)
    }
    
    // MARK: Notifications
    
    @objc private func accessibilityVoiceOverStatusChanged(notification: NSNotification) {
        updateUserInterface(index: paperOnboarding.currentIndex, animated: true)
    }
}

extension OnboardingViewController: PaperOnboardingDataSource {
    public func onboardingItemsCount() -> Int {
        return onboarding.pages.count
    }
    
    public func onboardingItem(at index: Int) -> OnboardingItemInfo {
        let page = onboarding.pages[index]
        
        let informationImage = UIImage(named: "\(onboarding.uid)_\(page.uid)-200") ?? UIImage()
        let pageIcon = UIImage(named: "\(onboarding.uid)_\(page.uid)-45") ?? UIImage()
        
        let titleFontSize = CGFloat(isTall ? 24.0 : 20.0)
        let subtitleFontSize = CGFloat(isTall ? 15.0 : 14.0)
        
        return OnboardingItemInfo(informationImage: informationImage,
                                  title: PlaySRGOnboardingLocalizedString(page.title, nil),
                                  description: PlaySRGOnboardingLocalizedString(page.text, nil),
                                  pageIcon: pageIcon,
                                  color: page.color,
                                  titleColor: .white,
                                  descriptionColor: .white,
                                  titleFont: SRGFont.font(family: .text, weight: .medium, fixedSize: titleFontSize),
                                  descriptionFont: SRGFont.font(family: .text, weight: .medium, fixedSize: subtitleFontSize),
                                  descriptionLabelPadding: 30.0,
                                  titleLabelPadding: 15.0)
    }
}

extension OnboardingViewController: PaperOnboardingDelegate {
    public func onboardingWillTransitonToIndex(_ index: Int) {
        updateUserInterface(index: index, animated: true)
    }
    
    public func onboardingDidTransitonToIndex(_: Int) {
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: paperOnboarding)
    }
    
    public func onboardingConfigurationItem(_ item: OnboardingContentViewItem, index _: Int) {
        item.titleLabel?.numberOfLines = 2
        item.descriptionLabel?.numberOfLines = 0
        
        let constant = CGFloat(isTall ? 200.0 : 120.0)
        item.informationImageWidthConstraint?.constant = constant
        item.informationImageHeightConstraint?.constant = constant
        
        item.titleCenterConstraint?.constant = isTall ? 50.0 : 20.0
    }
}

extension OnboardingViewController: SRGAnalyticsViewTracking {
    public var srg_pageViewTitle: String {
        return onboarding.title
    }
    
    public var srg_pageViewLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.application.rawValue, AnalyticsPageLevel.feature.rawValue]
    }
}
