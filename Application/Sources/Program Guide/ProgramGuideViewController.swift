//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import UIKit

// MARK: View controller

final class ProgramGuideViewController: UIViewController {
    private var model: ProgramGuideViewModel
    private let pageViewController: UIPageViewController
    
    private weak var headerView: HostView<ProgramGuideHeaderView>!
    
    private var cancellables = Set<AnyCancellable>()
    
    private var pageViewControllerAnimated: Bool = false
    
    init(day: SRGDay = .today) {
        model = ProgramGuideViewModel(day: day, atCurrentTime: true)
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
        
        let headerView = HostView<ProgramGuideHeaderView>(frame: .zero)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        self.headerView = headerView
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 180),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView.content = ProgramGuideHeaderView(model: model)
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        addChild(pageViewController)
        if let pageView = pageViewController.view {
            pageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pageView)
            
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
                pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                pageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
        pageViewController.didMove(toParent: self)
        
        let dailyViewController = ProgramGuideDailyViewController(day: model.selectedDay.day, channel: model.selectedChannel)
        pageViewController.setViewControllers([dailyViewController], direction: .forward, animated: false, completion: nil)
        
        model.$selectedChannel
            .sink { [weak self] selectedChannel in
                self?.reloadData(with: selectedChannel)
            }
            .store(in: &cancellables)
        
        model.$selectedDay
            .sink { [weak self] selectedDay in
                self?.switchToDay(selectedDay.day, atCurrentTime: selectedDay.atCurrentTime)
            }
            .store(in: &cancellables)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if model.selectedDay.atCurrentTime, let currentViewController = pageViewController.viewControllers?.first as? ProgramGuideDailyViewController {
            currentViewController.needToScrollToCurrentTime()
        }
    }
    
    private func reloadData(with selectedChannel: SRGChannel?) {
        // See https://stackoverflow.com/a/27984538/760435
        for viewController in pageViewController.children {
            if let dailyViewController = viewController as? ProgramGuideDailyViewController {
                dailyViewController.channel = selectedChannel
            }
        }
    }
    
    private func switchToDay(_ day: SRGDay, atCurrentTime: Bool) {
        guard !pageViewControllerAnimated else { return }
        guard let currentViewController = pageViewController.viewControllers?.first as? ProgramGuideDailyViewController else { return }
        
        if currentViewController.day != day {
            let direction: UIPageViewController.NavigationDirection = (day.date < currentViewController.day.date) ? .reverse : .forward
            let dailyViewController = ProgramGuideDailyViewController(day: day, channel: model.selectedChannel)
            pageViewController.setViewControllers([dailyViewController], direction: direction, animated: true) { completed in
                if completed, atCurrentTime {
                    dailyViewController.needToScrollToCurrentTime()
                }
            }
        }
        else if atCurrentTime {
            currentViewController.needToScrollToCurrentTime()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
}

// MARK: Protocols

extension ProgramGuideViewController: SRGAnalyticsViewTracking {
    var srg_pageViewTitle: String {
        return AnalyticsPageTitle.programGuide.rawValue
    }
    
    var srg_pageViewLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
    }
}

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
        pageViewControllerAnimated = true
        
        guard let currentViewController = pendingViewControllers.first as? ProgramGuideDailyViewController else { return }
        model.selectedDay = (currentViewController.day, false)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed {
            pageViewControllerAnimated = true
            
            guard let currentViewController = previousViewControllers.first as? ProgramGuideDailyViewController else { return }
            model.selectedDay = (currentViewController.day, false)
        }
        else {
            pageViewControllerAnimated = false
        }
    }
}
