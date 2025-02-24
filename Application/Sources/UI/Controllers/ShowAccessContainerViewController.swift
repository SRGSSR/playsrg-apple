//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import Pageboy
import Tabman
import UIKit

final class ShowAccessContainerViewController: UIViewController {
    enum AccessType {
        case alphabetical
        case byDate
    }

    private let accessType: AccessType
    private let radioChannels: [RadioChannel]
    private let tabContainerViewController: TabContainerViewController
    private let tabBarItems: [TMBarItem]
    private let viewControllers: [UIViewController]
    private var cancellables: Set<AnyCancellable> = []

    init(accessType: AccessType, radioChannels: [RadioChannel]) {
        self.accessType = accessType
        self.radioChannels = radioChannels
        tabContainerViewController = TabContainerViewController()
        tabBarItems = radioChannels.enumerated()
            .map { index, radioChannel in
                UITabBarItem(title: radioChannel.name, image: RadioChannelLogoImage(radioChannel), tag: index)
            }
            .map { item in
                if let image = item.image {
                    let barItem = TMBarItem(image: image)
                    barItem.accessibilityLabel = item.title
                    return barItem
                } else {
                    let barItem = TMBarItem(title: item.title ?? "")
                    barItem.accessibilityLabel = item.title
                    return barItem
                }
            }
        viewControllers = radioChannels.map { radioChannel in
            switch accessType {
            case .alphabetical:
                SectionViewController(section: .configured(.radioAllShows(channelUid: radioChannel.uid)))
            case .byDate:
                CalendarViewController(radioChannel: radioChannel, date: nil)
            }
        }

        super.init(nibName: nil, bundle: nil)
        addChild(tabContainerViewController)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureBarView() {
        let barView = TMBarView<TMHorizontalBarLayout, TMTabItemBarButton, TMLineBarIndicator>()
        barView.backgroundView.style = .flat(color: .srgGray16)
        barView.layout.alignment = .centerDistributed
        barView.indicator.tintColor = .white
        tabContainerViewController.addBar(barView, dataSource: self, at: .top)
    }

    override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureBarView()
        if let tabContainerView = tabContainerViewController.view {
            view.insertSubview(tabContainerView, at: 0)

            tabContainerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tabContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tabContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                tabContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tabContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
        tabContainerViewController.didMove(toParent: self)
        tabContainerViewController.dataSource = self

        tabContainerViewController
            .updateSignal()
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                updateTitle()
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTitle()
    }

    private func updateTitle() {
        guard let currentViewController = tabContainerViewController.currentViewController,
              let indexOfCurrentSelection = viewControllers.firstIndex(of: currentViewController),
              indexOfCurrentSelection < radioChannels.count
        else {
            navigationItem.title = NSLocalizedString("Audios", comment: "Title displayed at the top of the audio view")
            return
        }

        navigationItem.title = radioChannels[indexOfCurrentSelection].name
    }
}

// MARK: - Protocols

extension ShowAccessContainerViewController: ContainerContentInsets {
    var play_additionalContentInsets: UIEdgeInsets {
        UIEdgeInsets(top: tabContainerViewController.barInsets.top, left: 0.0, bottom: 0.0, right: 0.0)
    }
}

extension ShowAccessContainerViewController: Oriented {
    var play_supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }

    var play_orientingChildViewControllers: [UIViewController] {
        viewControllers
    }
}

extension ShowAccessContainerViewController: SRGAnalyticsContainerViewTracking {
    var srg_activeChildViewControllers: [UIViewController] {
        [tabContainerViewController]
    }
}

extension ShowAccessContainerViewController: PageboyViewControllerDataSource, TMBarDataSource {
    func numberOfViewControllers(in _: PageboyViewController) -> Int {
        viewControllers.count
    }

    func viewController(for _: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        viewControllers[index]
    }

    func defaultPage(for _: PageboyViewController) -> PageboyViewController.Page? {
        .at(index: 0)
    }

    func barItem(for _: any TMBar, at index: Int) -> any TMBarItemable {
        tabBarItems[index]
    }
}
