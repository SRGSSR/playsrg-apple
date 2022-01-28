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
    private var targetTime: TimeInterval?
    
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
        dailyModel = ProgramGuideDailyViewModel(day: model.day, firstPartyChannels: model.firstPartyChannels, thirdPartyChannels: model.thirdPartyChannels)
        targetTime = model.time
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
        
        model.$day
            .removeDuplicates()
            .sink { [weak self] day in
                self?.dailyModel.day = day
            }
            .store(in: &cancellables)
        
        model.$time
            .sink { [weak self] time in
                if let self = self, !self.scrollToTime(time, animated: true) {
                    self.targetTime = time
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
            if state.isLoading {
                emptyView.content = EmptyView(state: .loading)
            }
            else if state.isEmpty {
                emptyView.content = EmptyView(state: .empty(type: .generic), layout: constant(iOS: .standard, tvOS: .text))
            }
            else {
                emptyView.content = nil
            }
#if os(tvOS)
            if let firstSection = state.sections.first,
               let currentProgram = state.items(for: firstSection).compactMap(\.program).first(where: { $0.play_contains(model.day.date) }) {
                headerView.content = ProgramGuideGridHeaderView(model: model, focusedProgram: currentProgram)
            }
            else {
                headerView.content = ProgramGuideGridHeaderView(model: model, focusedProgram: nil)
            }
#endif
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.dataSource.apply(Self.snapshot(from: state), animatingDifferences: false) {
                if let targetTime = self.targetTime, !state.isEmpty, self.scrollToTime(targetTime, animated: true) {
                    self.targetTime = nil
                }
            }
        }
    }
    
    private func updateLayout(for traitCollection: UITraitCollection? = nil) {
        let appliedTraitCollection = traitCollection ?? self.traitCollection
        headerHeightConstraint.constant = constant(iOS: appliedTraitCollection.horizontalSizeClass == .compact ? 180 : 140, tvOS: 760)
    }
    
    private func scrollToTime(_ time: TimeInterval, animated: Bool) -> Bool {
        guard let xOffset = ProgramGuideGridLayout.xOffset(centeringDate: model.date(for: time), in: collectionView, day: model.day) else { return false }
        collectionView.setContentOffset(CGPoint(x: xOffset, y: collectionView.contentOffset.y), animated: animated)
        return true
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
        guard let date = ProgramGuideGridLayout.date(centeredAtXOffset: collectionView.contentOffset.x, in: collectionView, day: dailyModel.day) else { return }
        let time = date.timeIntervalSince(dailyModel.day.date)
        model.didScrollToTime(time)
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
