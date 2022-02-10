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
    
    private weak var headerView: HostView<ProgramGuideHeaderView>!
    private weak var contentView: UIView!
    private weak var headerHeightConstraint: NSLayoutConstraint!
    
    private var cancellables = Set<AnyCancellable>()
    
    private var layout: ProgramGuideLayout = .grid {
        didSet {
            let previousViewController = children.compactMap { $0 as? UIViewController & ProgramGuideChildViewController }.first
            guard previousViewController == nil || layout != oldValue else { return }
            
            let dailyModel = previousViewController?.programGuideDailyViewModel
            
            if let previousViewController = previousViewController {
                previousViewController.view.removeFromSuperview()
                previousViewController.removeFromParent()
            }
            
            guard let viewController = viewController(for: layout, dailyModel: dailyModel) else { return }
            addChild(viewController)
            
            if let childView = viewController.view {
                childView.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(childView)
                
                NSLayoutConstraint.activate([
                    childView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: constant(iOS: 0, tvOS: -ProgramGuideGridLayout.timelineHeight)),
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
            
            viewController.didMove(toParent: self)
            
            headerView.isUserInteractionEnabled = true
            headerView.content = ProgramGuideHeaderView(model: model, layout: layout)
        }
    }
    
    private func viewController(for layout: ProgramGuideLayout, dailyModel: ProgramGuideDailyViewModel?) -> UIViewController? {
        switch layout {
        case .list:
#if os(iOS)
            return ProgramGuideListViewController(model: model, dailyModel: dailyModel)
#else
            return nil
#endif
        case .grid:
            return ProgramGuideGridViewController(model: model, dailyModel: dailyModel)
        }
    }
    
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
        
        let headerView = HostView<ProgramGuideHeaderView>(frame: .zero)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        self.headerView = headerView
        
        let headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: 0 /* set in updateLayout(for:) */)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: constant(iOS: view.safeAreaLayoutGuide.topAnchor, tvOS: view.topAnchor)),
            headerHeightConstraint,
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.headerHeightConstraint = headerHeightConstraint
        
#if os(iOS)
        model.$isUserInteractionEnabled
            .sink { isUserInteractionEnabled in
                headerView.isUserInteractionEnabled = isUserInteractionEnabled
            }
            .store(in: &cancellables)
        
        updateNavigationBar()
#endif
        updateLayout()
    }
    
#if os(iOS)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
#endif
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate { _ in
            self.updateLayout(for: newCollection)
        } completion: { _ in }
    }
    
#if os(tvOS)
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [headerView]
    }
    
    @objc private func menuPressed(_ gestureRecognizer: UIGestureRecognizer) {
        setNeedsFocusUpdate()
    }
#endif
    
    private func updateLayout(for traitCollection: UITraitCollection? = nil) {
        let appliedTraitCollection = traitCollection ?? self.traitCollection
#if os(iOS)
        if ApplicationConfiguration.shared.areTvThirdPartyChannelsAvailable {
            layout = ApplicationSettingProgramGuideRecentlyUsedLayout()
        }
        else {
            layout = (appliedTraitCollection.horizontalSizeClass == .compact) ? .list : .grid
        }
#else
        layout = .grid
#endif
        headerHeightConstraint.constant = ProgramGuideHeaderViewSize.height(for: layout, horizontalSizeClass: appliedTraitCollection.horizontalSizeClass)
    }
    
#if os(iOS)
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
        switch layout {
        case .list:
            layout = .grid
        case .grid:
            layout = .list
        }
        ApplicationSettingSetProgramGuideRecentlyUsedLayout(layout)
        
        updateLayout()
        updateNavigationBar()
    }
#endif
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
