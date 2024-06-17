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

    private var cancellables = Set<AnyCancellable>()

    init(model: ProgramGuideViewModel, dailyModel: ProgramGuideDailyViewModel?) {
        self.model = model
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [
            UIPageViewController.OptionsKey.interPageSpacing: 100
        ])
        super.init(nibName: nil, bundle: nil)
        addChild(pageViewController)

        let dailyViewController = ProgramGuideDailyViewController(day: model.day, programGuideModel: model, programGuideDailyModel: dailyModel)
        pageViewController.setViewControllers([dailyViewController], direction: .forward, animated: false)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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

        if let pageView = pageViewController.view {
            view.addSubview(pageView)

            pageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: view.topAnchor),
                pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                pageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
        pageViewController.didMove(toParent: self)

        model.$change
            .sink { [weak self] change in
                switch change {
                case let .day(day), let .dayAndTime(day: day, time: _):
                    self?.switchToDay(day)
                default:
                    break
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
              currentViewController.day != day else { return }
        let direction: UIPageViewController.NavigationDirection = (day.date < currentViewController.day.date) ? .reverse : .forward
        let dailyViewController = ProgramGuideDailyViewController(day: day, programGuideModel: model)
        pageViewController.setViewControllers([dailyViewController], direction: direction, animated: true, completion: { [weak self] _ in
            self?.play_setNeedsScrollableViewUpdate()
        })
    }
}

// MARK: Protocols

extension ProgramGuideListViewController: ProgramGuideChildViewController {
    var programGuideLayout: ProgramGuideLayout {
        .list
    }

    var programGuideDailyViewModel: ProgramGuideDailyViewModel? {
        if let currentViewController = pageViewController.viewControllers?.first as? ProgramGuideDailyViewController {
            currentViewController.programGuideDailyViewModel
        } else {
            nil
        }
    }
}

extension ProgramGuideListViewController: ScrollableContentContainer {
    var play_scrollableChildViewController: UIViewController? {
        pageViewController.viewControllers?.first
    }
}

extension ProgramGuideListViewController: UIPageViewControllerDataSource {
    func pageViewController(_: UIPageViewController, viewControllerBefore _: UIViewController) -> UIViewController? {
        let previousDay = SRGDay(byAddingDays: -1, months: 0, years: 0, to: model.day)
        return ProgramGuideDailyViewController(day: previousDay, programGuideModel: model)
    }

    func pageViewController(_: UIPageViewController, viewControllerAfter _: UIViewController) -> UIViewController? {
        let nextDay = SRGDay(byAddingDays: 1, months: 0, years: 0, to: model.day)
        return ProgramGuideDailyViewController(day: nextDay, programGuideModel: model)
    }
}

extension ProgramGuideListViewController: UIPageViewControllerDelegate {
    func pageViewController(_: UIPageViewController, willTransitionTo _: [UIViewController]) {
        model.isHeaderUserInteractionEnabled = false
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating _: Bool, previousViewControllers _: [UIViewController], transitionCompleted completed: Bool) {
        model.isHeaderUserInteractionEnabled = true

        if completed, let currentViewController = pageViewController.viewControllers?.first as? ProgramGuideDailyViewController {
            model.switchToDay(currentViewController.day)
            play_setNeedsScrollableViewUpdate()
        }
    }
}
