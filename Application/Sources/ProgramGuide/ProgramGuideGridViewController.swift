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
    
    private var scrollTarget: ScrollTarget?
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>!
    
    private weak var collectionView: UICollectionView!
    private weak var emptyContentView: HostView<EmptyContentView>!
    
    private static func snapshot(from state: ProgramGuideDailyViewModel.State) -> NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>()
        for section in state.sections {
            snapshot.appendSections([section])
            snapshot.appendItems(state.items(for: section), toSection: section)
        }
        return snapshot
    }
    
    init(model: ProgramGuideViewModel, dailyModel: ProgramGuideDailyViewModel?) {
        self.model = model
        scrollTarget = ScrollTarget(channel: model.selectedChannel, time: model.time)
        if let dailyModel, dailyModel.day == model.day {
            self.dailyModel = dailyModel
        }
        else {
            self.dailyModel = ProgramGuideDailyViewModel(day: model.day, firstPartyChannels: model.firstPartyChannels, thirdPartyChannels: model.thirdPartyChannels)
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: ProgramGuideGridLayout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = constant(iOS: .automatic, tvOS: .never)
        collectionView.isDirectionalLockEnabled = true
        collectionView.horizontalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: ProgramGuideGridLayout.channelHeaderWidth, bottom: 0, right: 0)
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: ProgramGuideGridLayout.timelineHeight, left: 0, bottom: 0, right: 0)
        
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: constant(iOS: 0, tvOS: 56)),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let emptyContentView = HostView<EmptyContentView>(frame: .zero)
        collectionView.backgroundView = emptyContentView
        self.emptyContentView = emptyContentView
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            guard let self else { return }
            let snapshot = self.dataSource.snapshot()
            let channel = snapshot.sectionIdentifiers[indexPath.section]
            view.content = ChannelHeaderView(channel: channel)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerViewRegistration, for: indexPath)
        }
        
        collectionView.collectionViewLayout.register(TimelineDecorationView.self, forDecorationViewOfKind: ProgramGuideGridLayout.ElementKind.timeline.rawValue)
        collectionView.collectionViewLayout.register(NowArrowDecorationView.self, forDecorationViewOfKind: ProgramGuideGridLayout.ElementKind.nowArrow.rawValue)
        collectionView.collectionViewLayout.register(NowLineDecorationView.self, forDecorationViewOfKind: ProgramGuideGridLayout.ElementKind.nowLine.rawValue)
        
        dailyModel.$state
            .sink { [weak self] state in
                self?.reloadData(for: state)
            }
            .store(in: &cancellables)
        
        model.$change
            .sink { [weak self] change in
                guard let self else { return }
                switch change {
                case let .day(day):
                    self.dailyModel.day = day
                case let .time(time):
                    self.scrollToTarget(ScrollTarget(time: time), animated: true)
                case let .dayAndTime(day: day, time: time):
                    self.dailyModel.day = day
                    self.scrollToTarget(ScrollTarget(time: time), animated: true)
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        scrollToTarget(ScrollTarget(channel: model.selectedChannel, time: model.time), animated: false)
    }
    
    private func reloadData(for state: ProgramGuideDailyViewModel.State) {
        switch state {
        case let .failed(error: error):
            emptyContentView.content = EmptyContentView(state: .failed(error: error))
        case .content:
            if state.isLoading {
                emptyContentView.content = EmptyContentView(state: .loading)
            }
            else if state.isEmpty {
                emptyContentView.content = EmptyContentView(state: .empty(type: .generic), layout: constant(iOS: .standard, tvOS: .text))
            }
            else {
                emptyContentView.content = nil
            }
#if os(tvOS)
            if let channel = model.selectedChannel ?? model.channels.first, let section = state.sections.first(where: { $0 == channel }) ?? state.sections.first,
               let currentProgram = state.items(for: section).compactMap(\.program).first(where: { $0.play_contains(model.date(for: model.time)) }) {
                model.focusedProgram = currentProgram
            }
            else {
                model.focusedProgram = nil
            }
#endif
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.dataSource.apply(Self.snapshot(from: state), animatingDifferences: false) {
                if !state.isEmpty {
                    // Ensure correct content size before attempting to scroll, otherwise scrolling might not work
                    // when because of a still undetermined content size.
                    self.collectionView.layoutIfNeeded()
                    self.scrollToTarget(self.scrollTarget, animated: false)
                }
            }
        }
    }
}

// MARK: Scrolling management

private extension ProgramGuideGridViewController {
    func xOffset(for time: TimeInterval?) -> CGFloat? {
        guard let time else { return nil }
        return ProgramGuideGridLayout.xOffset(centeringDate: model.date(for: time), in: collectionView, day: model.day)
    }
    
    func yOffset(for channel: SRGChannel?) -> CGFloat? {
        guard let channel, let sectionIndex = dataSource.snapshot().sectionIdentifiers.firstIndex(of: channel) else { return nil }
        return ProgramGuideGridLayout.yOffset(forSectionIndex: sectionIndex, in: collectionView)
    }
    
    func offset(for target: ScrollTarget) -> CGPoint? {
        if let x = xOffset(for: target.time) {
            return CGPoint(x: x, y: yOffset(for: target.channel) ?? collectionView.contentOffset.y)
        }
        else if let y = yOffset(for: target.channel) {
            return CGPoint(x: collectionView.contentOffset.x, y: y)
        }
        else {
            return nil
        }
    }
    
    func scrollToTarget(_ target: ScrollTarget?, animated: Bool) {
        if let target, let offset = offset(for: target) {
            collectionView.setContentOffset(offset, animated: animated)
            scrollTarget = nil
        }
        else {
            scrollTarget = target
        }
    }
}

// MARK: Types

private extension ProgramGuideGridViewController {
    struct ScrollTarget {
        let channel: SRGChannel?
        let time: TimeInterval?
        
        init?(channel: SRGChannel?, time: TimeInterval?) {
            guard channel != nil || time != nil else { return nil }
            self.channel = channel
            self.time = time
        }
        
        init(channel: SRGChannel) {
            self.channel = channel
            self.time = nil
        }
        
        init(time: TimeInterval) {
            self.channel = nil
            self.time = time
        }
    }
}

// MARK: Protocols

extension ProgramGuideGridViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        return collectionView != nil ? [collectionView] : nil
    }
    
    var play_paddingContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: ProgramGuideGridLayout.verticalSpacing, right: 0)
    }
}

extension ProgramGuideGridViewController: ProgramGuideChildViewController {
    var programGuideLayout: ProgramGuideLayout {
        return .grid
    }
    
    var programGuideDailyViewModel: ProgramGuideDailyViewModel? {
        return dailyModel
    }
}

#if os(iOS)
extension ProgramGuideGridViewController: ScrollableContent {
    var play_scrollableView: UIScrollView? {
        return collectionView
    }
}
#endif

extension ProgramGuideGridViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let channel = snapshot.sectionIdentifiers[indexPath.section]
        guard let program = snapshot.itemIdentifiers(inSection: channel)[indexPath.row].program else {
            deselectItems(in: collectionView, animated: true)
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
            model.selectedChannel = channel
            model.focusedProgram = snapshot.itemIdentifiers(inSection: channel)[nextFocusedIndexPath.row].program
        }
    }
#endif
}

extension ProgramGuideGridViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let sectionIndex = ProgramGuideGridLayout.sectionIndex(atYOffset: collectionView.contentOffset.y, in: collectionView)
        guard let channel = dataSource.snapshot().sectionIdentifiers[safeIndex: sectionIndex] else { return }
        model.selectedChannel = channel
        
        guard let date = ProgramGuideGridLayout.date(centeredAtXOffset: collectionView.contentOffset.x, in: collectionView, day: dailyModel.day) else { return }
        let time = date.timeIntervalSince(dailyModel.day.date)
        model.didScrollToTime(time)
    }
    
#if os(iOS)
    // The system default behavior does not lead to correct results when large titles are displayed. Override.
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollView.play_scrollToTop(animated: true)
        return false
    }
#endif
}

// MARK: Views

private extension ProgramGuideGridViewController {
    struct ItemCell: View {
        let item: ProgramGuideDailyViewModel.Item
        
        var body: some View {
            switch item.wrappedValue {
            case let .program(program):
                ProgramCell(program: program, channel: item.section, direction: .vertical)
            case .loading:
                LoadingCell()
            case .empty:
                Color.clear
            }
        }
    }
    
    final class TimelineDecorationView: HostSupplementaryView<TimelineView> {
        override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
            guard let timelineAttributes = layoutAttributes as? TimelineLayoutAttributes else { return }
            content = TimelineView(dateInterval: timelineAttributes.dateInterval)
        }
    }
    
    final class NowArrowDecorationView: HostSupplementaryView<NowArrowView> {
        override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
            content = NowArrowView()
        }
    }

    final class NowLineDecorationView: HostSupplementaryView<NowLineView> {
        override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
            content = NowLineView()
        }
    }
}
