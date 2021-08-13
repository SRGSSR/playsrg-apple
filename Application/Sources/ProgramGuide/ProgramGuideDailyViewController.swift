//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import UIKit

// MARK: View controller

final class ProgramGuideDailyViewController: UIViewController {
    private let model: ProgramGuideDailyViewModel
    
    private let programGuideModel: ProgramGuideViewModel
    
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<ProgramGuideDailyViewModel.Section, SRGProgram>!
    
    private weak var collectionView: UICollectionView!
    private weak var emptyView: HostView<EmptyView>!
    
    var day: SRGDay {
        return model.day
    }
    
    private static func snapshot(from state: ProgramGuideDailyViewModel.State, for channel: SRGChannel?) -> NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, SRGProgram> {
        var snapshot = NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, SRGProgram>()
        snapshot.appendSections([.main])
        snapshot.appendItems(state.programs(for: channel), toSection: .main)
        return snapshot
    }
    
    init(day: SRGDay, programGuideModel: ProgramGuideViewModel) {
        model = ProgramGuideDailyViewModel(day: day)
        self.programGuideModel = programGuideModel
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
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        let emptyView = HostView<EmptyView>(frame: .zero)
        collectionView.backgroundView = emptyView
        self.emptyView = emptyView
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellRegistration = UICollectionView.CellRegistration<HostCollectionViewCell<ProgramCell>, SRGProgram> { cell, _, program in
            cell.content = ProgramCell(program: program)
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
        
        programGuideModel.$dateSelection
            .sink { [weak self] dateSelection in
                if dateSelection.transition == .time {
                    self?.scrollToTime(dateSelection.time, animated: true)
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.scrollToTime(animated: false)
    }
    
    private func reloadData(for channel: SRGChannel? = nil) {
        reloadData(for: model.state, channel: channel)
    }
    
    private func reloadData(for state: ProgramGuideDailyViewModel.State, channel: SRGChannel? = nil) {
        guard let emptyView = emptyView, let dataSource = dataSource else { return }
        
        let channel = channel ?? programGuideModel.selectedChannel
        
        switch state {
        case .loading:
            emptyView.content = EmptyView(state: .loading)
        case let .failed(error: error):
            emptyView.content = EmptyView(state: .failed(error: error))
        case .loaded:
            emptyView.content = state.programs(for: channel).isEmpty ? EmptyView(state: .empty(type: .generic)) : nil
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            dataSource.apply(Self.snapshot(from: state, for: channel), animatingDifferences: false) {
                // Ensure correct content size before attempting to scroll, otherwise scrolling might not work
                // when the content size has not yet been determined (still zero).
                self.collectionView.layoutIfNeeded()
                self.scrollToTime(animated: false)
            }
        }
    }
    
    private func scrollToTime(_ time: TimeInterval? = nil, animated: Bool) {
        let date = model.day.date.addingTimeInterval(time ?? programGuideModel.dateSelection.time)
        let programs = model.state.programs(for: programGuideModel.selectedChannel)
        guard let row = programs.firstIndex(where: { $0.endDate > date }) else { return }
        collectionView.scrollToItem(at: IndexPath(row: row, section: 0), at: .top, animated: animated)
    }
}

// MARK: Protocols

extension ProgramGuideDailyViewController: ContentInsets {
    var play_contentScrollViews: [UIScrollView]? {
        return collectionView != nil ? [collectionView] : nil
    }
    
    var play_paddingContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 6, right: 0)
    }
}

extension ProgramGuideDailyViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Deselection is managed here rather than in view appearance methods, as those are not called with the
        // modal presentation we use.
        guard let channel = programGuideModel.selectedChannel else {
            self.deselectItems(in: collectionView, animated: true)
            return
        }
        
        let program = dataSource.snapshot().itemIdentifiers(inSection: .main)[indexPath.row]
        let programViewController = ProgramView.viewController(for: program, channel: channel)
        present(programViewController, animated: true) {
            self.deselectItems(in: collectionView, animated: true)
        }
    }
}

extension ProgramGuideDailyViewController: UIScrollViewDelegate {
    private func updateTime() {
        if let index = collectionView.indexPathsForVisibleItems.sorted().first?.row,
           let program = model.state.programs(for: programGuideModel.selectedChannel)[safeIndex: index] {
            programGuideModel.scrollToTime(of: program.startDate)
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

// MARK: Layout

private extension ProgramGuideDailyViewController {
    private func layout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, layoutEnvironment in
            let layoutWidth = layoutEnvironment.container.effectiveContentSize.width
            let section = NSCollectionLayoutSection.horizontal(layoutWidth: layoutWidth) { _, _ in
                return ProgramCellSize.fullWidth()
            }
            section.interGroupSpacing = 3
            return section
        }
    }
}
