//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

// MARK: View controller

final class ProgramGuideViewController: UIViewController {
    private enum Layout {
        case none
        @available(tvOS, unavailable)
        case list
        case grid
    }
    
    private let model: ProgramGuideViewModel
    
    private var layout: Layout = .none {
        didSet {
            guard layout != oldValue else { return }
            
            let previousViewController = children.compactMap { $0 as? UIViewController & ProgramGuideChildViewController }.first
            let dailyModel = previousViewController?.programGuideDailyViewModel
            
            if let previousViewController = previousViewController {
                previousViewController.view.removeFromSuperview()
                previousViewController.removeFromParent()
            }
            
            if let viewController = viewController(for: layout, dailyModel: dailyModel) {
                addChild(viewController)
                viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                viewController.view.frame = view.bounds
                view.addSubview(viewController.view)
                viewController.didMove(toParent: self)
            }
        }
    }
    
    private func viewController(for layout: Layout, dailyModel: ProgramGuideDailyViewModel?) -> UIViewController? {
        switch layout {
#if os(iOS)
        case .list:
            return ProgramGuideListViewController(model: model, dailyModel: dailyModel)
#endif
        case .grid:
            return ProgramGuideGridViewController(model: model, dailyModel: dailyModel)
        case .none:
            return nil
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
        updateLayout()
#if os(iOS)
        updateNavigationBar()
#endif
    }
    
#if os(iOS)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
#endif
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayout()
    }
    
    private func updateLayout() {
#if os(iOS)
        if ApplicationConfiguration.shared.areTvThirdPartyChannelsAvailable {
            guard layout == .none else { return }
            layout = .grid
        }
        else {
            layout = (traitCollection.horizontalSizeClass == .compact) ? .list : .grid
        }
#else
        layout = .grid
#endif
    }
    
#if os(iOS)
    private func updateNavigationBar() {
        if ApplicationConfiguration.shared.areTvThirdPartyChannelsAvailable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: (layout == .grid) ? "rectangle.grid.1x2" : "square.grid.3x2"),
                style: .plain,
                target: self,
                action: #selector(toggleLayout(_:))
            )
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
        case .none:
            break
        }
        updateNavigationBar()
    }
#endif
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
