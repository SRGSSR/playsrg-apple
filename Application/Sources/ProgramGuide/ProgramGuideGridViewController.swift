//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAppearanceSwift
import SwiftUI
import UIKit

// MARK: View controller

final class ProgramGuideGridViewController: UIViewController {
    private let model: ProgramGuideViewModel
    private let dailyModel: ProgramGuideDailyViewModel
    
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<SRGChannel, SRGProgram>!
    
    private weak var headerView: HostView<ProgramGuideGridHeaderView>!
    private weak var collectionView: UICollectionView!
    private weak var emptyView: HostView<EmptyView>!
    
    private static func snapshot(from state: ProgramGuideDailyViewModel.State) -> NSDiffableDataSourceSnapshot<SRGChannel, SRGProgram> {
        var snapshot = NSDiffableDataSourceSnapshot<SRGChannel, SRGProgram>()
        for channel in state.channels {
            snapshot.appendSections([channel])
            snapshot.appendItems(state.programs(for: channel), toSection: channel)
        }
        return snapshot
    }
    
    init(model: ProgramGuideViewModel) {
        self.model = model
        dailyModel = ProgramGuideDailyViewModel(day: SRGDay(from: model.dateSelection.date))
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        
        let headerView = HostView<ProgramGuideGridHeaderView>(frame: .zero)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        self.headerView = headerView
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: constant(iOS: view.safeAreaLayoutGuide.topAnchor, tvOS: view.topAnchor)),
            headerView.heightAnchor.constraint(equalToConstant: constant(iOS: 100, tvOS: 600)),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: ProgramGuideGridLayout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = constant(iOS: .automatic, tvOS: .never)
        collectionView.isDirectionalLockEnabled = true
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let emptyView = HostView<EmptyView>(frame: .zero)
        collectionView.backgroundView = emptyView
        self.emptyView = emptyView
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
#if os(tvOS)
        headerView.content = ProgramGuideGridHeaderView(model: model, focusedProgram: nil)
#else
        headerView.content = ProgramGuideGridHeaderView(model: model)
#endif
        
        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<ProgramCell>, SRGProgram> { cell, _, program in
            cell.content = ProgramCell(program: program, direction: .vertical)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        let headerViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<ChannelHeaderView>>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] view, _, indexPath in
            guard let self = self else { return }
            let snapshot = self.dataSource.snapshot()
            let channel = snapshot.sectionIdentifiers[indexPath.section]
            view.content = ChannelHeaderView(channel: channel)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerViewRegistration, for: indexPath)
        }
        
        collectionView.collectionViewLayout.register(TimelineDecorationView.self, forDecorationViewOfKind: ProgramGuideGridLayout.ElementKind.timeline.rawValue)
        collectionView.collectionViewLayout.register(VerticalNowIndicatorDecorationView.self, forDecorationViewOfKind: ProgramGuideGridLayout.ElementKind.verticalNowIndicator.rawValue)
        
        dailyModel.$state
            .sink { [weak self] state in
                self?.reloadData(for: state)
            }
            .store(in: &cancellables)
        
        model.$dateSelection
            .sink { [weak self] dateSelection in
                switch dateSelection.transition {
                case .day:
                    self?.switchToDay(dateSelection.day)
                case .time:
                    self?.scrollToTime(dateSelection.time, animated: true)
                case .none:
                    break
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
        
        switch state {
        case .loading:
            emptyView.content = EmptyView(state: .loading)
        case let .failed(error: error):
            emptyView.content = EmptyView(state: .failed(error: error))
        case .loaded:
            emptyView.content = !state.hasContent ? EmptyView(state: .empty(type: .generic)) : nil
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            dataSource.apply(Self.snapshot(from: state), animatingDifferences: false) {
                // Ensure correct content size before attempting to scroll, otherwise scrolling might not work
                // when the content size has not yet been determined (still zero).
                self.collectionView.layoutIfNeeded()
                self.scrollToTime(animated: false)
            }
        }
    }
    
    private func switchToDay(_ day: SRGDay) {
        dailyModel.day = day
    }
    
    private func scrollToTime(_ time: TimeInterval? = nil, animated: Bool) {
        let date = dailyModel.day.date.addingTimeInterval(time ?? model.dateSelection.time)
        let channel = dailyModel.state.channels.first
        let programs = dailyModel.state.programs(for: channel)
        guard let row = programs.firstIndex(where: { $0.endDate > date }) else { return }
        collectionView.play_scrollToItem(at: IndexPath(row: row, section: 0), at: .centeredHorizontally, animated: animated)
    }
}

// MARK: Protocols

extension ProgramGuideGridViewController: ProgramGuideGridHeaderViewActions {
    func openCalendar() {
#if os(iOS)
        let calendarViewController = ProgramGuideCalendarViewController(model: model)
        present(calendarViewController, animated: true)
#endif
    }
}

extension ProgramGuideGridViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let channel = snapshot.sectionIdentifiers[indexPath.section]
        let program = snapshot.itemIdentifiers(inSection: channel)[indexPath.row]
#if os(tvOS)
        navigateToProgram(program, in: channel)
#else
        // Deselection is managed here rather than in view appearance methods, as those are not called with the
        // modal presentation we use.
        let programViewController = ProgramView.viewController(for: program, channel: channel)
        present(programViewController, animated: true) {
            self.deselectItems(in: collectionView, animated: true)
        }
#endif
    }
    
#if os(tvOS)
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let previouslyFocusedIndexPath = context.previouslyFocusedIndexPath, let previouslyFocusedCell = collectionView.cellForItem(at: previouslyFocusedIndexPath) as? HostCollectionViewCell<ProgramCell> {
            previouslyFocusedCell.isUIKitFocused = false
        }
        if let nextFocusedIndexPath = context.nextFocusedIndexPath {
            if let nextFocusedCell = collectionView.cellForItem(at: nextFocusedIndexPath) as? HostCollectionViewCell<ProgramCell> {
                nextFocusedCell.isUIKitFocused = true
            }
            
            let snapshot = dataSource.snapshot()
            let channel = snapshot.sectionIdentifiers[nextFocusedIndexPath.section]
            let program = snapshot.itemIdentifiers(inSection: channel)[nextFocusedIndexPath.row]
            headerView.content = ProgramGuideGridHeaderView(model: model, focusedProgram: program)
        }
        else {
            headerView.content = ProgramGuideGridHeaderView(model: model, focusedProgram: nil)
        }
    }
#endif
}

extension ProgramGuideGridViewController: UIScrollViewDelegate {
    private func updateTime() {
        if let indexPath = collectionView.indexPathsForVisibleItems.sorted().first,
           let channel = dailyModel.state.channels[safeIndex: indexPath.section],
           let program = dailyModel.state.programs(for: channel)[safeIndex: indexPath.row] {
            model.didScrollToTime(of: program.startDate)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateTime()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateTime()
        }
    }
}

// MARK: Views

final class TimelineDecorationView: HostSupplementaryView<TimelineView> {
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        guard let timelineAttributes = layoutAttributes as? TimelineLayoutAttributes else { return }
        content = TimelineView(dateInterval: timelineAttributes.dateInterval)
    }
}

final class VerticalNowIndicatorDecorationView: HostSupplementaryView<VerticalNowIndicatorView> {
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        content = VerticalNowIndicatorView()
    }
}
