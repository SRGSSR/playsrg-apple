//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import UIKit

// MARK: View controller

final class ProgramGuideViewController: UIViewController {
    private let day: SRGDay
    private var model: ProgramGuideViewModel
    private let pageViewController: UIPageViewController
    
    private var cancellables = Set<AnyCancellable>()
    
    init(day: SRGDay = .today) {
        self.day = day
        model = ProgramGuideViewModel(day: day)
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [
            UIPageViewController.OptionsKey.interPageSpacing: 100
        ])
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Program guide", comment: "Program guide title")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        addChild(pageViewController)
        if let pageView = pageViewController.view {
            pageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pageView)
            
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: view.topAnchor),
                pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                pageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
        pageViewController.didMove(toParent: self)
        
        let todayViewController = ProgramGuideDailyViewController(day: day, channel: model.selectedChannel)
        pageViewController.setViewControllers([todayViewController], direction: .forward, animated: false, completion: nil)
        
        model.$selectedChannel
            .sink { [weak self] selectedChannel in
                self?.reloadData(with: selectedChannel)
            }
            .store(in: &cancellables)
    }
    
    private func reloadData(with selectedChannel: SRGChannel?) {
        if let title = selectedChannel?.title {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(changeChannel))
        }
        else {
            navigationItem.rightBarButtonItem = nil
        }
        
        if let currentViewController = pageViewController.viewControllers?.first as? ProgramGuideDailyViewController {
            currentViewController.channel = selectedChannel
        }
    }
    
    @objc private func changeChannel(_ sender: UIBarButtonItem) {
        model.nextChannel()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
}

// MARK: Protocols

extension ProgramGuideViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentViewController = viewController as? ProgramGuideDailyViewController else { return nil }
        let previousDay = SRGDay(byAddingDays: -1, months: 0, years: 0, to: currentViewController.day)
        return ProgramGuideDailyViewController(day: previousDay, channel: model.selectedChannel)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentViewController = viewController as? ProgramGuideDailyViewController else { return nil }
        let nextDay = SRGDay(byAddingDays: 1, months: 0, years: 0, to: currentViewController.day)
        return ProgramGuideDailyViewController(day: nextDay, channel: model.selectedChannel)
    }
}

extension ProgramGuideViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        // TODO: Update header
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        // TODO: Update header
    }
}
