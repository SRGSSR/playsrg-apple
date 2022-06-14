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
    
    private weak var headerHostView: UIView!
    private weak var headerView: HostView<ProgramGuideHeaderView>!
    private weak var headerHostHeightConstraint: NSLayoutConstraint!
    private weak var headerHeightConstraint: NSLayoutConstraint!
    private weak var headerTopConstraint: NSLayoutConstraint!
    
    private var _layout: ProgramGuideLayout = .grid     // Pseudo ivar to implement animated and non-animated setters
    private var cancellables = Set<AnyCancellable>()
    
    private static let transitionDuration: TimeInterval = 0.4
    
    init(date: Date? = nil) {
        model = ProgramGuideViewModel(date: date ?? Date())
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("TV guide", comment: "TV program guide view title")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .srgGray16
        
        let headerHostView = UIView()
        view.addSubview(headerHostView)
        self.headerHostView = headerHostView
        
        let headerHostHeightConstraint = headerHostView.heightAnchor.constraint(equalToConstant: 0 /* set in transition(to:traitCollection:animated:) */)
        
        headerHostView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerHostView.topAnchor.constraint(equalTo: constant(iOS: view.safeAreaLayoutGuide.topAnchor, tvOS: view.topAnchor)),
            headerHostHeightConstraint,
            headerHostView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerHostView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.headerHostHeightConstraint = headerHostHeightConstraint
        
        let headerView = HostView<ProgramGuideHeaderView>(frame: .zero)
        headerHostView.addSubview(headerView)
        self.headerView = headerView
        
        let headerTopConstraint = headerView.topAnchor.constraint(equalTo: headerHostView.topAnchor)
        let headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: 0 /* set in transition(to:traitCollection:animated:) */)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerTopConstraint,
            headerHeightConstraint,
            headerView.leadingAnchor.constraint(equalTo: headerHostView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: headerHostView.trailingAnchor)
        ])
        self.headerTopConstraint = headerTopConstraint
        self.headerHeightConstraint = headerHeightConstraint
        
        _layout = Self.layout(for: traitCollection)
        transition(to: _layout, traitCollection: traitCollection, animated: false)
        
#if os(iOS)
        model.$isHeaderUserInteractionEnabled
            .sink { isHeaderUserInteractionEnabled in
                headerView.isUserInteractionEnabled = isHeaderUserInteractionEnabled
            }
            .store(in: &cancellables)
        
        navigationItem.largeTitleDisplayMode = .always
        updateNavigationBar()
#endif
    }

#if os(iOS)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate { _ in
            self.transition(to: Self.layout(for: newCollection), traitCollection: newCollection, animated: false)
        } completion: { _ in }
    }
    
    private func updateNavigationBar() {
        let isGrid = (layout == .grid)
        let layoutBarButtonItem = UIBarButtonItem(
            image: UIImage(named: isGrid ? "layout_grid_on" : "layout_list_on"),
            style: .plain,
            target: self,
            action: #selector(toggleLayout(_:))
        )
        layoutBarButtonItem.accessibilityLabel = isGrid
            ? PlaySRGAccessibilityLocalizedString("Display list", comment: "Button to display the TV guide as a list")
            : PlaySRGAccessibilityLocalizedString("Display grid", comment: "Button to display the TV guide as a grid")
        navigationItem.rightBarButtonItem = layoutBarButtonItem
    }
    
    @objc private func toggleLayout(_ sender: AnyObject) {
        func toggle(to layout: ProgramGuideLayout) {
            setLayout(layout, animated: true)
            ApplicationSettingSetProgramGuideRecentlyUsedLayout(layout)
        }
        
        switch layout {
        case .list:
            toggle(to: .grid)
        case .grid:
            toggle(to: .list)
        }
        updateNavigationBar()
    }
#endif
    
    private static func layout(for traitCollection: UITraitCollection) -> ProgramGuideLayout {
        return constant(iOS: ApplicationSettingProgramGuideRecentlyUsedLayout(), tvOS: .grid)
    }
    
#if os(tvOS)
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [headerView]
    }
    
    @objc private func menuPressed(_ gestureRecognizer: UIGestureRecognizer) {
        setNeedsFocusUpdate()
    }
#endif
}

// MARK: Layout

extension ProgramGuideViewController {
    private func setLayout(_ layout: ProgramGuideLayout, animated: Bool) {
        guard layout != _layout else { return }
        _layout = layout
        transition(to: layout, traitCollection: traitCollection, animated: animated)
    }
    
    private var layout: ProgramGuideLayout {
        get {
            return _layout
        }
        set {
            setLayout(newValue, animated: false)
        }
    }
    
    private func addProgramGuideChild(_ viewController: UIViewController) {
        addChild(viewController)
        
        let childView = viewController.view!
#if os(tvOS)
        view.addSubview(childView)
#else
        view.insertSubview(childView, at: 0)
#endif
        
        childView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.topAnchor.constraint(equalTo: headerHostView.bottomAnchor, constant: constant(iOS: 0, tvOS: -ProgramGuideGridLayout.timelineHeight)),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
#if os(tvOS)
        let menuGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(menuPressed(_:)))
        menuGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        childView.addGestureRecognizer(menuGestureRecognizer)
#endif
    }
    
    private func transition(to layout: ProgramGuideLayout, traitCollection: UITraitCollection, animated: Bool) {
        let headerHeight = ProgramGuideHeaderViewSize.height(for: layout, horizontalSizeClass: traitCollection.horizontalSizeClass)
        headerView.content = ProgramGuideHeaderView(model: model, layout: layout)
        headerHeightConstraint.constant = headerHeight
        
        if let previousViewController = children.first as? UIViewController & ProgramGuideChildViewController {
            if previousViewController.programGuideLayout != layout {
                previousViewController.willMove(toParent: nil)
                
                let viewController = viewController(for: layout, dailyModel: previousViewController.programGuideDailyViewModel)
                addProgramGuideChild(viewController)
                
                if animated {
                    viewController.view.alpha = 0
                    view.layoutIfNeeded()
                    UIView.animate(withDuration: Self.transitionDuration) {
                        previousViewController.view.alpha = 0
                        viewController.view.alpha = 1
                        self.headerHostHeightConstraint.constant = headerHeight
                        self.view.layoutIfNeeded()
                    } completion: { _ in
                        previousViewController.view.removeFromSuperview()
                        previousViewController.removeFromParent()
                        viewController.didMove(toParent: self)
                        self.play_setNeedsScrollableViewUpdate()
#if os(iOS)
                        self.model.isHeaderUserInteractionEnabled = true
#endif
                    }
                }
                else {
                    headerHostHeightConstraint.constant = headerHeight
                    previousViewController.view.removeFromSuperview()
                    previousViewController.removeFromParent()
                    viewController.didMove(toParent: self)
                    play_setNeedsScrollableViewUpdate()
#if os(iOS)
                    model.isHeaderUserInteractionEnabled = true
#endif
                }
            }
            else {
                if animated {
                    view.layoutIfNeeded()
                    UIView.animate(withDuration: Self.transitionDuration) {
                        self.headerHostHeightConstraint.constant = headerHeight
                        self.view.layoutIfNeeded()
                    } completion: { _ in
#if os(iOS)
                        self.model.isHeaderUserInteractionEnabled = true
#endif
                    }
                }
                else {
                    headerHostHeightConstraint.constant = headerHeight
#if os(iOS)
                    model.isHeaderUserInteractionEnabled = true
#endif
                }
            }
        }
        else {
            let viewController = viewController(for: layout, dailyModel: nil)
            addProgramGuideChild(viewController)
            viewController.didMove(toParent: self)
            headerHostHeightConstraint.constant = headerHeight
#if os(iOS)
            model.isHeaderUserInteractionEnabled = true
#endif
        }
    }
    
    private func viewController(for layout: ProgramGuideLayout, dailyModel: ProgramGuideDailyViewModel?) -> UIViewController {
        switch layout {
        case .list:
#if os(iOS)
            return ProgramGuideListViewController(model: model, dailyModel: dailyModel)
#else
            return ProgramGuideGridViewController(model: model, dailyModel: dailyModel)
#endif
        case .grid:
            return ProgramGuideGridViewController(model: model, dailyModel: dailyModel)
        }
    }
}

// MARK: Protocols

extension ProgramGuideViewController: ScrollableContentContainer {
    var play_scrollableChildViewController: UIViewController? {
        return children.first
    }
    
    func play_contentOffsetDidChange(inScrollableView scrollView: UIScrollView) {
        headerTopConstraint.constant = max(-scrollView.contentOffset.y - scrollView.adjustedContentInset.top, 0)
    }
}

#if os(iOS)
extension ProgramGuideViewController: ProgramGuideHeaderViewActions {
    func openCalendar() {
        let calendarViewController = ProgramGuideCalendarViewController(model: model)
        present(calendarViewController, animated: true)
    }
}
#endif

extension ProgramGuideViewController: SRGAnalyticsViewTracking {
    var srg_pageViewTitle: String {
        return AnalyticsPageTitle.programGuide.rawValue
    }
    
    var srg_pageViewLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
    }
}
