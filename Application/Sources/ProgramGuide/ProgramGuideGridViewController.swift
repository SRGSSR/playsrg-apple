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
        
        let headerView = HostView<ProgramGuideGridHeaderView>(frame: .zero)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        self.headerView = headerView
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: constant(iOS: 120, tvOS: 180)),
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
        
        let emptyView = HostView<EmptyView>(frame: .zero)
        collectionView.backgroundView = emptyView
        self.emptyView = emptyView
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView.content = ProgramGuideGridHeaderView(model: model)
        
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
        
        let timelineViewRegistration = UICollectionView.SupplementaryRegistration<HostSupplementaryView<TimelineView>>(elementKind: ProgramGuideGridLayout.ElementKind.timeline.rawValue) { [weak self] view, _, _ in
            guard let self = self else { return }
            let snapshot = self.dataSource.snapshot()
            view.content = TimelineView(dateInterval: snapshot.dateInterval)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerViewRegistration, for: indexPath)
            case ProgramGuideGridLayout.ElementKind.timeline.rawValue:
                return collectionView.dequeueConfiguredReusableSupplementary(using: timelineViewRegistration, for: indexPath)
            default:
                return nil
            }
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
        
        switch state {
        case .loading:
            emptyView.content = EmptyView(state: .loading)
        case let .failed(error: error):
            emptyView.content = EmptyView(state: .failed(error: error))
        case .loaded:
            emptyView.content = nil
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            dataSource.apply(Self.snapshot(from: state), animatingDifferences: true)
        }
    }
    
    private func switchToDay(_ day: SRGDay) {
        dailyModel.day = day
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

extension ProgramGuideGridViewController: ProgramGuideGridHeaderViewActions {
    func openCalendar() {
    #if os(iOS)
        let calendarViewController = ProgramGuideCalendarViewController(model: model)
        present(calendarViewController, animated: true)
    #endif
    }
}

extension ProgramGuideGridViewController: UICollectionViewDelegate {
#if os(iOS)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Deselection is managed here rather than in view appearance methods, as those are not called with the
        // modal presentation we use.
        let snapshot = dataSource.snapshot()
        let channel = snapshot.sectionIdentifiers[indexPath.section]
        let program = snapshot.itemIdentifiers(inSection: channel)[indexPath.row]
        let programViewController = ProgramView.viewController(for: program, channel: channel)
        present(programViewController, animated: true) {
            self.deselectItems(in: collectionView, animated: true)
        }
    }
#endif
    
#if os(tvOS)
    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return false
    }
#endif
}

// MARK: Headers

private extension ProgramGuideGridViewController {
    struct ChannelHeaderView: View {
        let channel: SRGChannel
        
        private var logoImage: UIImage? {
            guard let tvChannel = ApplicationConfiguration.shared.tvChannel(forUid: channel.uid) else { return nil }
            return TVChannelLargeLogoImage(tvChannel)
        }
        
        var body: some View {
            Group {
                if let image = logoImage {
                    Image(uiImage: image)
                }
                else {
                    Text(channel.title)
                        .srgFont(.button)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // See https://stackoverflow.com/a/68765719/760435
            .background(
                Color.srgGray23
                    .shadow(color: Color(white: 0, opacity: 0.6), radius: 10, x: 0, y: 0)
                    .mask(Rectangle().padding(.trailing, -40))
            )
        }
    }
    
    // TODO: Extract & create preview
    struct TimelineView: View {
        let dateInterval: DateInterval?
        
        // TODO: Factor out common constants, at the correct location
        private static let scale: CGFloat = constant(iOS: 650, tvOS: 900) / (60 * 60)
        private static let channelHeaderWidth: CGFloat = constant(iOS: 130, tvOS: 220)
        private static let horizontalSpacing: CGFloat = constant(iOS: 2, tvOS: 4)
        
        private static let dateComponents: DateComponents = {
            var dateComponents = DateComponents()
            dateComponents.minute = 0
            return dateComponents
        }()
        
        private static func label(for date: Date) -> String {
            return DateFormatter.play_time.string(from: date)
        }
        
        private func xPosition(for date: Date) -> CGFloat {
            guard let dateInterval = dateInterval else { return 0 }
            return Self.channelHeaderWidth + Self.horizontalSpacing + date.timeIntervalSince(dateInterval.start) * Self.scale
        }
        
        private var dates: [Date] {
            guard let dateInterval = dateInterval else { return [] }
            
            var dates = [Date]()
            Calendar.current.enumerateDates(startingAfter: dateInterval.start, matching: Self.dateComponents, matchingPolicy: .nextTime) { date, _, stop in
                guard let date = date else { return }
                if dateInterval.contains(date) {
                    dates.append(date)
                }
                else {
                    stop = true
                }
            }
            return dates
        }
        
        var body: some View {
            GeometryReader { geometry in
                ForEach(dates, id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(Self.label(for: date))
                            .srgFont(.caption)
                            .foregroundColor(.white)
                        Rectangle()
                            .fill(Color.srgGray96)
                            .frame(width: 1, height: 15)
                    }
                    .position(x: xPosition(for: date), y: geometry.size.height / 2)
                    .padding(.bottom, 8)
                }
            }
        }
    }
}
