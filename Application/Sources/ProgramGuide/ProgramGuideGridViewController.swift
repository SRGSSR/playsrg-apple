//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import UIKit

// MARK: View controller

final class ProgramGuideGridViewController: UIViewController {
    private let model: ProgramGuideViewModel
    private let dailyModel: ProgramGuideDailyViewModel
    
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<SRGChannel, SRGProgram>!
    
    private weak var headerView: HostView<ProgramGuideHeaderView>!
    private weak var collectionView: UICollectionView!
    
    private static func snapshot(from state: ProgramGuideDailyViewModel.State) -> NSDiffableDataSourceSnapshot<SRGChannel, SRGProgram> {
        var snapshot = NSDiffableDataSourceSnapshot<SRGChannel, SRGProgram>()
        for channel in state.channels {
            snapshot.appendSections([channel])
            snapshot.appendItems(state.programs(for: channel), toSection: channel)
        }
        return snapshot
    }
    
    init(date: Date? = nil) {
        let initialDate = date ?? Date()
        model = ProgramGuideViewModel(date: initialDate)
        dailyModel = ProgramGuideDailyViewModel(day: SRGDay(from: initialDate))
        
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("TV guide", comment: "TV program guide view title")
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
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: ProgramGuideGridLayout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView.content = ProgramGuideHeaderView(model: model)
        
        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<ProgramCell>, SRGProgram> { cell, _, program in
            cell.content = ProgramCell(program: program)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        dailyModel.$state
            .sink { [weak self] state in
                self?.reloadData(for: state)
            }
            .store(in: &cancellables)
        
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
    
    private func reloadData(for state: ProgramGuideDailyViewModel.State) {
        guard let dataSource = dataSource else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            dataSource.apply(Self.snapshot(from: state), animatingDifferences: true)
        }
    }
    
    private func switchToDay(_ day: SRGDay) {
        
    }
    
    #if os(iOS)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
    #endif
}

// MARK: Protocols

extension ProgramGuideGridViewController: SRGAnalyticsViewTracking {
    var srg_pageViewTitle: String {
        return AnalyticsPageTitle.programGuide.rawValue
    }
    
    var srg_pageViewLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
    }
}

extension ProgramGuideGridViewController: ProgramGuideHeaderViewActions {
    func openCalendar() {
    #if os(iOS)
        let calendarViewController = ProgramGuideCalendarViewController(model: model)
        present(calendarViewController, animated: true)
    #endif
    }
}

extension ProgramGuideGridViewController: UICollectionViewDelegate {
    
}
