//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import UIKit

// MARK: View controller

final class ProgramGuideListViewController: UIViewController {
    private let model: ProgramGuideViewModel
    private let pageViewController: UIPageViewController
    
    private weak var headerView: HostView<ProgramGuideListHeaderView>!
    
    private var cancellables = Set<AnyCancellable>()
    
    init(model: ProgramGuideViewModel) {
        self.model = model
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [
            UIPageViewController.OptionsKey.interPageSpacing: 100
        ])
        super.init(nibName: nil, bundle: nil)
        addChild(pageViewController)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        
        let headerView = HostView<ProgramGuideListHeaderView>(frame: .zero)
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
        
        headerView.content = ProgramGuideListHeaderView(model: model)
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
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
                if dateSelection.transition == .day {
                    self?.switchToDay(dateSelection.day)
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func switchToDay(_ day: SRGDay) {
        guard let currentViewController = pageViewController.viewControllers?.first as? ProgramGuideDailyViewController,
              currentViewController.day != day else {
            return
        }
        
        let direction: UIPageViewController.NavigationDirection = (day.date < currentViewController.day.date) ? .reverse : .forward
        let dailyViewController = ProgramGuideDailyViewController(day: day, programGuideModel: model)
        pageViewController.setViewControllers([dailyViewController], direction: direction, animated: true, completion: nil)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
}

// MARK: Protocols

extension ProgramGuideListViewController: SRGAnalyticsViewTracking {
    var srg_pageViewTitle: String {
        return AnalyticsPageTitle.programGuide.rawValue
    }
    
    var srg_pageViewLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
    }
}

extension ProgramGuideListViewController: ProgramGuideListHeaderViewActions {
    func openCalendar() {
        let calendarViewController = ProgramGuideCalendarViewController(model: model)
        present(calendarViewController, animated: true)
    }
}

extension ProgramGuideListViewController: UIPageViewControllerDataSource {
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

extension ProgramGuideListViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        headerView.isUserInteractionEnabled = false
        
        guard let currentViewController = pendingViewControllers.first as? ProgramGuideDailyViewController else { return }
        model.scrollToDay(currentViewController.day)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        headerView.isUserInteractionEnabled = true
        
        if !completed {
            guard let currentViewController = previousViewControllers.first as? ProgramGuideDailyViewController else { return }
            model.scrollToDay(currentViewController.day)
        }
    }
}
