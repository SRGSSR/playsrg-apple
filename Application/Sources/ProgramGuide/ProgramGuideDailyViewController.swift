//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SwiftUI
import UIKit

// MARK: View controller

final class ProgramGuideDailyViewController: UIViewController {
    private let model: ProgramGuideDailyViewModel
    private let programGuideModel: ProgramGuideViewModel
    
    private var scrollTargetTime: TimeInterval?
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>!
    
    private weak var collectionView: UICollectionView!
    private weak var emptyView: HostView<EmptyView>!
    
    private static let margin: CGFloat = 10
    private static let verticalSpacing: CGFloat = 3
    
    var day: SRGDay {
        return model.day
    }
    
    private static func snapshot(from state: ProgramGuideDailyViewModel.State, for channel: SRGChannel?) -> NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>()
        if let channel = channel {
            snapshot.appendSections([channel])
            snapshot.appendItems(state.items(for: channel), toSection: channel)
        }
        return snapshot
    }
    
    init(day: SRGDay, programGuideModel: ProgramGuideViewModel, programGuideDailyModel: ProgramGuideDailyViewModel? = nil) {
        if let programGuideDailyModel = programGuideDailyModel, programGuideDailyModel.day == programGuideModel.day {
            model = programGuideDailyModel
        }
        else {
            model = ProgramGuideDailyViewModel(day: day, firstPartyChannels: programGuideModel.firstPartyChannels, thirdPartyChannels: programGuideModel.thirdPartyChannels)
        }
        self.programGuideModel = programGuideModel
        scrollTargetTime = programGuideModel.time
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Self.margin),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Self.margin)
        ])
        
        let emptyView = HostView<EmptyView>(frame: .zero)
        collectionView.backgroundView = emptyView
        self.emptyView = emptyView
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<ItemCell>, ProgramGuideDailyViewModel.Item> { cell, _, item in
            cell.content = ItemCell(item: item)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        model.$state
            .sink { [weak self] state in
                self?.reloadData(for: state)
            }
            .store(in: &cancellables)
        
        programGuideModel.$data
            .sink { [weak self] data in
                self?.reloadData(for: data.selectedChannel)
            }
            .store(in: &cancellables)
        
        programGuideModel.$change
            .sink { [weak self] change in
                guard let self = self else { return }
                switch change {
                case let .time(time):
                    self.scrollToTime(time, animated: true)
                case .channel:
                    self.scrollToTime(self.programGuideModel.time, animated: false)
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO: Just for PoC
        if #available(iOS 15, *) {
            parent?.parent?.parent?.setContentScrollView(collectionView)
        }
        
        scrollToTime(programGuideModel.time, animated: false)
    }
    
    private func reloadData(for channel: SRGChannel? = nil) {
        reloadData(for: model.state, channel: channel)
    }
    
    private func reloadData(for state: ProgramGuideDailyViewModel.State, channel: SRGChannel? = nil) {
        let currentChannel = channel ?? self.programGuideModel.selectedChannel
        
        switch state {
        case let .failed(error: error):
            emptyView.content = EmptyView(state: .failed(error: error))
        case .content:
            if state.isLoading(in: currentChannel) {
                emptyView.content = EmptyView(state: .loading)
            }
            else if state.isEmpty(in: currentChannel) {
                emptyView.content = EmptyView(state: .empty(type: .generic))
            }
            else {
                emptyView.content = nil
            }
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.dataSource.apply(Self.snapshot(from: state, for: currentChannel), animatingDifferences: false) {
                if let channel = currentChannel, !state.isEmpty(in: channel) {
                    // Ensure correct content size before attempting to scroll, otherwise scrolling might not work
                    // when because of a still undetermined content size.
                    self.collectionView.layoutIfNeeded()
                    self.scrollToTime(self.scrollTargetTime, animated: false)
                }
            }
        }
    }
    
    private func scrollToTime(_ time: TimeInterval?, animated: Bool) {
        if let time = time, let yOffset = yOffset(for: day.date.addingTimeInterval(time)) {
            collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: yOffset), animated: animated)
            scrollTargetTime = nil
        }
        else {
            scrollTargetTime = time
        }
    }
}

// MARK: Layout calculations

extension ProgramGuideDailyViewController {
    private static func safeYOffset(_ yOffset: CGFloat, in collectionView: UICollectionView) -> CGFloat {
        let maxYOffset = max(collectionView.contentSize.height - collectionView.frame.height
            + collectionView.adjustedContentInset.top + collectionView.adjustedContentInset.bottom, 0)
        return yOffset.clamped(to: 0...maxYOffset)
    }
    
    func date(atYOffset yOffset: CGFloat) -> Date? {
        guard let selectedChannel = programGuideModel.selectedChannel,
              let index = collectionView.indexPathForItem(at: CGPoint(x: collectionView.contentOffset.x, y: yOffset))?.row,
              let program = model.state.items(for: selectedChannel)[safeIndex: index]?.program else { return nil }
        return program.startDate
    }
    
    func yOffset(for date: Date) -> CGFloat? {
        guard collectionView.contentSize != .zero,
              let selectedChannel = programGuideModel.selectedChannel,
              let nearestRow = model.state.items(for: selectedChannel).firstIndex(where: { $0.endsAfter(date) }),
              let layoutAttr = collectionView.layoutAttributesForItem(at: IndexPath(row: nearestRow, section: 0)) else { return nil }
        return Self.safeYOffset(layoutAttr.frame.minY, in: collectionView)
    }
}

// MARK: Protocols

extension ProgramGuideDailyViewController: ProgramGuideChildViewController {
    var programGuideLayout: ProgramGuideLayout {
        return .list
    }
    
    var programGuideDailyViewModel: ProgramGuideDailyViewModel? {
        return model
    }
}

extension ProgramGuideDailyViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        return collectionView != nil ? [collectionView] : nil
    }
    
    var play_paddingContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: Self.verticalSpacing, right: 0)
    }
}

extension ProgramGuideDailyViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Deselection is managed here rather than in view appearance methods, as those are not called with the
        // modal presentation we use.
        guard let channel = programGuideModel.selectedChannel,
              let program = dataSource.snapshot().itemIdentifiers(inSection: channel)[indexPath.row].program else {
            deselectItems(in: collectionView, animated: true)
            return
        }
        
        let programViewController = ProgramView.viewController(for: program, channel: channel)
        present(programViewController, animated: true) {
            self.deselectItems(in: collectionView, animated: true)
        }
    }
}

extension ProgramGuideDailyViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let date = date(atYOffset: collectionView.contentOffset.y) else { return }
        programGuideModel.didScrollToTime(date.timeIntervalSince(day.date))
    }
}

// MARK: Views

private extension ProgramGuideDailyViewController {
    struct ItemCell: View {
        let item: ProgramGuideDailyViewModel.Item
        
        var body: some View {
            if let program = item.program {
                ProgramCell(program: program, channel: item.section, direction: .horizontal)
            }
            else {
                Color.clear
            }
        }
    }
}

// MARK: Layout

private extension ProgramGuideDailyViewController {
    private func layout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, layoutEnvironment in
            let layoutWidth = layoutEnvironment.container.effectiveContentSize.width
            let section = NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth) { _, _ in
                return ProgramCellSize.fullWidth()
            }
            section.interGroupSpacing = Self.verticalSpacing
            return section
        }
    }
}
