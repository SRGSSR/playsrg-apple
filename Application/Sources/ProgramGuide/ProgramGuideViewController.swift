//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import UIKit

// MARK: View controller

final class ProgramGuideViewController: UIViewController {
    private let model: ProgramGuideViewModel
    private let pageViewController: UIPageViewController
    
    private weak var headerView: HostView<ProgramGuideHeaderView>!
    
    private var cancellables = Set<AnyCancellable>()
    
    private var pageViewControllerAnimated: Bool = false
    
    init(date: Date = Date()) {
        model = ProgramGuideViewModel(date: date)
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
        
        let dailyViewController = ProgramGuideDailyViewController(day: model.dateSelection.day, programGuideModel: model)
        pageViewController.setViewControllers([dailyViewController], direction: .forward, animated: false)
        
        model.$dateSelection
            .sink { [weak self] dateSelection in
                guard let self = self else { return }
                self.switchToDay(dateSelection.day)
            }
            .store(in: &cancellables)
    }
    
    private func switchToDay(_ day: SRGDay) {
        guard !pageViewControllerAnimated,
              let currentViewController = pageViewController.viewControllers?.first as? ProgramGuideDailyViewController,
              currentViewController.day != day else {
            return
        }
        
        let direction: UIPageViewController.NavigationDirection = (day.date < currentViewController.day.date) ? .reverse : .forward
        let dailyViewController = ProgramGuideDailyViewController(day: day, programGuideModel: model)
        pageViewController.setViewControllers([dailyViewController], direction: direction, animated: true, completion: { [weak self] _ in
            self?.pageViewControllerAnimated = false
        })
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
        return ProgramGuideDailyViewController(day: previousDay, programGuideModel: model)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentViewController = viewController as? ProgramGuideDailyViewController else { return nil }
        let nextDay = SRGDay(byAddingDays: 1, months: 0, years: 0, to: currentViewController.day)
        return ProgramGuideDailyViewController(day: nextDay, programGuideModel: model)
    }
}

extension ProgramGuideViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pageViewControllerAnimated = true
        
        guard let currentViewController = pendingViewControllers.first as? ProgramGuideDailyViewController else { return }
        model.atDay(currentViewController.day)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed {
            pageViewControllerAnimated = true
            
            guard let currentViewController = previousViewControllers.first as? ProgramGuideDailyViewController else { return }
            model.atDay(currentViewController.day)
        }
        else {
            pageViewControllerAnimated = false
        }
    }
}
