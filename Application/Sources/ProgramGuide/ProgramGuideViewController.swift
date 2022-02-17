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
        headerHostView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerHostView)
        self.headerHostView = headerHostView
        
        let headerHostHeightConstraint = headerHostView.heightAnchor.constraint(equalToConstant: 0 /* set in transition(to:traitCollection:animated:) */)
        NSLayoutConstraint.activate([
            headerHostView.topAnchor.constraint(equalTo: constant(iOS: view.safeAreaLayoutGuide.topAnchor, tvOS: view.topAnchor)),
            headerHostHeightConstraint,
            headerHostView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerHostView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.headerHostHeightConstraint = headerHostHeightConstraint
        
        let headerView = HostView<ProgramGuideHeaderView>(frame: .zero)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerHostView.addSubview(headerView)
        self.headerView = headerView
        
        let headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: 0 /* set in transition(to:traitCollection:animated:) */)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: headerHostView.topAnchor),
            headerHeightConstraint,
            headerView.leadingAnchor.constraint(equalTo: headerHostView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: headerHostView.trailingAnchor)
        ])
        self.headerHeightConstraint = headerHeightConstraint
        
        _layout = Self.layout(for: traitCollection)
        transition(to: _layout, traitCollection: traitCollection, animated: false)
        
#if os(iOS)
        model.$isHeaderUserInteractionEnabled
            .sink { isHeaderUserInteractionEnabled in
                headerView.isUserInteractionEnabled = isHeaderUserInteractionEnabled
            }
            .store(in: &cancellables)
        
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
        if ApplicationConfiguration.shared.areTvThirdPartyChannelsAvailable {
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
        else {
            navigationItem.rightBarButtonItem = nil
        }
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
#if os(iOS)
        if ApplicationConfiguration.shared.areTvThirdPartyChannelsAvailable {
            return ApplicationSettingProgramGuideRecentlyUsedLayout()
        }
        else {
            return (traitCollection.horizontalSizeClass == .compact) ? .list : .grid
        }
#else
        return .grid
#endif
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
        childView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childView)
        
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
                        self.model.isHeaderUserInteractionEnabled = true
                    }
                }
                else {
                    headerHostHeightConstraint.constant = headerHeight
                    previousViewController.view.removeFromSuperview()
                    previousViewController.removeFromParent()
                    viewController.didMove(toParent: self)
                    model.isHeaderUserInteractionEnabled = true
                }
            }
            else {
                if animated {
                    view.layoutIfNeeded()
                    UIView.animate(withDuration: Self.transitionDuration) {
                        self.headerHostHeightConstraint.constant = headerHeight
                        self.view.layoutIfNeeded()
                    } completion: { _ in
                        self.model.isHeaderUserInteractionEnabled = true
                    }
                }
                else {
                    headerHostHeightConstraint.constant = headerHeight
                    model.isHeaderUserInteractionEnabled = true
                }
            }
        }
        else {
            let viewController = viewController(for: layout, dailyModel: nil)
            addProgramGuideChild(viewController)
            viewController.didMove(toParent: self)
            headerHostHeightConstraint.constant = headerHeight
            model.isHeaderUserInteractionEnabled = true
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
