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
    private var dataSource: UICollectionViewDiffableDataSource<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>!
    
    private weak var headerView: HostView<ProgramGuideGridHeaderView>!
    private weak var collectionView: UICollectionView!
    private weak var emptyView: HostView<EmptyView>!
    
    private weak var headerHeightConstraint: NSLayoutConstraint!
    
    private static func snapshot(from state: ProgramGuideDailyViewModel.State) -> NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>()
        for section in state.sections {
            snapshot.appendSections([section])
            snapshot.appendItems(state.items(for: section), toSection: section)
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
        
        let headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: 0 /* set in updateLayout(for:) */)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: constant(iOS: view.safeAreaLayoutGuide.topAnchor, tvOS: view.topAnchor)),
            headerHeightConstraint,
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.headerHeightConstraint = headerHeightConstraint
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: ProgramGuideGridLayout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = constant(iOS: .automatic, tvOS: .never)
        collectionView.isDirectionalLockEnabled = true
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -ProgramGuideGridLayout.timelineHeight),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: constant(iOS: 0, tvOS: 56)),
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
        
        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<ItemCell>, ProgramGuideDailyViewModel.Item> { cell, _, item in
            cell.content = ItemCell(item: item)
#if os(tvOS)
            if let program = item.program {
                cell.accessibilityLabel = program.play_accessibilityLabel(with: item.section)
                cell.accessibilityHint = PlaySRGAccessibilityLocalizedString("Opens details.", comment: "Program cell hint")
            }
            else {
                cell.accessibilityLabel = nil
                cell.accessibilityHint = nil
            }
#endif
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
        
        updateLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate { _ in
            self.updateLayout(for: newCollection)
        } completion: { _ in }
    }
    
    private func reloadData(for state: ProgramGuideDailyViewModel.State) {
        switch state {
        case let .failed(error: error):
            emptyView.content = EmptyView(state: .failed(error: error))
        case .content:
            emptyView.content = state.isLoading ? EmptyView(state: .loading) : nil
#if os(tvOS)
            if let firstSection = state.sections.first,
               let currentProgram = state.items(for: firstSection).compactMap(\.program).first(where: { $0.play_contains(model.dateSelection.date) }) {
                headerView.content = ProgramGuideGridHeaderView(model: model, focusedProgram: currentProgram)
            }
            else {
                headerView.content = ProgramGuideGridHeaderView(model: model, focusedProgram: nil)
            }
#endif
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.dataSource.apply(Self.snapshot(from: state), animatingDifferences: false) {
                // Ensure correct content size before attempting to scroll, otherwise scrolling might not work
                // when the content size has not yet been determined (still zero).
                self.collectionView.layoutIfNeeded()
                self.scrollToTime(animated: false)
            }
        }
    }
    
    private func updateLayout(for traitCollection: UITraitCollection? = nil) {
        let appliedTraitCollection = traitCollection ?? self.traitCollection
        headerHeightConstraint.constant = constant(iOS: appliedTraitCollection.horizontalSizeClass == .compact ? 180 : 140, tvOS: 760)
    }
    
    private func switchToDay(_ day: SRGDay) {
        dailyModel.day = day
    }
    
    // FIXME: We must scroll to the correct section which was previously visible
    private func scrollToTime(_ time: TimeInterval? = nil, animated: Bool) {
        let date = dailyModel.day.date.addingTimeInterval(time ?? model.dateSelection.time)
        guard let section = dailyModel.state.sections.first else { return }
        let items = dailyModel.state.items(for: section)
        guard let row = items.firstIndex(where: { $0.endsAfter(date) }) else { return }
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
        guard let program = snapshot.itemIdentifiers(inSection: channel)[indexPath.row].program else {
            self.deselectItems(in: collectionView, animated: true)
            return
        }
        
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
        if let previouslyFocusedIndexPath = context.previouslyFocusedIndexPath,
            let previouslyFocusedCell = collectionView.cellForItem(at: previouslyFocusedIndexPath) as? HostCollectionViewCell<ItemCell> {
            previouslyFocusedCell.isUIKitFocused = false
        }
        if let nextFocusedIndexPath = context.nextFocusedIndexPath {
            if let nextFocusedCell = collectionView.cellForItem(at: nextFocusedIndexPath) as? HostCollectionViewCell<ItemCell> {
                nextFocusedCell.isUIKitFocused = true
            }
            
            let snapshot = dataSource.snapshot()
            let channel = snapshot.sectionIdentifiers[nextFocusedIndexPath.section]
            let program = snapshot.itemIdentifiers(inSection: channel)[nextFocusedIndexPath.row].program
            headerView.content = ProgramGuideGridHeaderView(model: model, focusedProgram: program)
        }
    }
#endif
}

extension ProgramGuideGridViewController: UIScrollViewDelegate {
    private func updateTime() {
        if let indexPath = collectionView.indexPathsForVisibleItems.sorted().first,
           let section = dailyModel.state.sections[safeIndex: indexPath.section],
           let program = dailyModel.state.items(for: section)[safeIndex: indexPath.row]?.program {
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

private extension ProgramGuideGridViewController {
    struct ItemCell: View {
        let item: ProgramGuideDailyViewModel.Item
        
        var body: some View {
            if let program = item.program {
                ProgramCell(program: program, channel: item.section, direction: .vertical)
            }
            else {
                Color.clear
            }
        }
    }
}

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
