//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderModel
import UIKit

// MARK: Layout

/**
 *  ┌────────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 *  │                │                                                                                                                   │
 *  │                │                                         Timeline (decoration)                                                     │
 *  │───────────────┬┼─────────────────────────────────────────────────────────┬┬────────────────────────────────┬┬────────────┬────────┬┤
 *  │               ││                                                         ││                                ││            │        ││
 *  │               ││                                                         ││                                ││            │        ││
 *  │    Header     ││                          00                             ││              01                ││     02     │        ││
 *  │               ││                                                         ││                                ││            │        ││
 *  │               │├─────────────────────────────────────────────────────────┴┴────────────────────────────────┴┴────────────┴────────┤│
 *  │───────────────┤├─────────────────────────┬────────────────────────────┬┬────────────────────┬─────────────────────────────────────┤│
 *  │               ││                         │                            ││                    │                                     ││
 *  │               ││                         │                            ││                    │                                     ││
 *  │    Header     ││                         │           10               ││        11          │                                     ││
 *  │               ││                         │                            ││                    │                                     ││
 *  │               │├─────────────────────────┴────────────────────────────┴┴────────────────────┴─────────────────────────────────────┤│
 *  │───────────────┤├─────────────┬─────────────────────────┬┬────────────────────────────────────────────────────────────┬┬───────────┤│
 *  │               ││             │                         ││                                                            ││           ││
 *  │               ││             │                         ││                                                            ││           ││
 *  │    Header     ││             │          20             ││                             21                             ││     22    ││
 *  │               ││             │                         ││                                                            ││           ││
 *  │               │├─────────────┴─────────────────────────┴┴────────────────────────────────────────────────────────────┴┴───────────┤│
 *  │───────────────┤├─────────────────┬────────────────────────────────┬┬──────────────────────────────────────────────────────────┬───┤│
 *  │               ││                 │                                ││                                                          │   ││
 *  │               ││                 │                                ││                                                          │   ││
 *  │    Header     ││                 │               30               ││                             31                           │   ││
 *  │               ││                 │                                ││                                                          │   ││
 *  └───────────────┴┴─────────────────┴────────────────────────────────┴┴──────────────────────────────────────────────────────────┴───┴┘
 */
final class ProgramGuideGridLayout: UICollectionViewLayout {
    enum ElementKind: String {
        case timeline
        case verticalNowIndicator
    }
    
    static let verticalNowIndicatorIndexPath = IndexPath(item: 0, section: 0)
    
    private struct LayoutData {
        let layoutAttrs: [UICollectionViewLayoutAttributes]
        let supplementaryAttrs: [UICollectionViewLayoutAttributes]
        let decorationAttrs: [UICollectionViewLayoutAttributes]
        let dateInterval: DateInterval
    }
    
    private static let horizontalSpacing: CGFloat = constant(iOS: 2, tvOS: 4)
    private static let verticalSpacing: CGFloat = constant(iOS: 3, tvOS: 6)
    private static let scale: CGFloat = constant(iOS: 650, tvOS: 900) / (60 * 60)
    private static let sectionHeight: CGFloat = constant(iOS: 105, tvOS: 120)
    private static let channelHeaderWidth: CGFloat = constant(iOS: 130, tvOS: 220)
    private static let trailingMargin: CGFloat = 10
    private static let timelineHeight: CGFloat = constant(iOS: 40, tvOS: 60)
    
    private var layoutData: LayoutData?
    private var cancellables = Set<AnyCancellable>()
    
    private static func startDate(from snapshot: NSDiffableDataSourceSnapshot<SRGChannel, SRGProgram>) -> Date? {
        return snapshot.sectionIdentifiers.flatMap { channel in
            return snapshot.itemIdentifiers(inSection: channel).map(\.startDate)
        }.min()
    }
    
    private static func endDate(from snapshot: NSDiffableDataSourceSnapshot<SRGChannel, SRGProgram>) -> Date? {
        return snapshot.sectionIdentifiers.flatMap { channel in
            return snapshot.itemIdentifiers(inSection: channel).map(\.endDate)
        }.max()
    }
    
    private static func dateInterval(from snapshot: NSDiffableDataSourceSnapshot<SRGChannel, SRGProgram>) -> DateInterval? {
        guard let startDate = startDate(from: snapshot), let endDate = endDate(from: snapshot) else { return nil }
        return DateInterval(start: startDate, end: endDate)
    }
    
    private static func layoutData(from snapshot: NSDiffableDataSourceSnapshot<SRGChannel, SRGProgram>, in collectionView: UICollectionView) -> LayoutData? {
        guard let dateInterval = dateInterval(from: snapshot) else { return nil }
        let layoutAttrs = snapshot.sectionIdentifiers.enumeratedFlatMap { channel, section in
            return snapshot.itemIdentifiers(inSection: channel).enumeratedMap { program, item -> UICollectionViewLayoutAttributes in
                let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: section))
                attrs.frame = CGRect(
                    x: Self.channelHeaderWidth + Self.horizontalSpacing + program.startDate.timeIntervalSince(dateInterval.start) * Self.scale,
                    y: Self.timelineHeight + CGFloat(section) * (Self.sectionHeight + Self.verticalSpacing),
                    width: max(program.endDate.timeIntervalSince(program.startDate) * Self.scale - Self.horizontalSpacing, 0),
                    height: Self.sectionHeight
                )
                return attrs
            }
        }
        let headerAttrs = snapshot.sectionIdentifiers.enumeratedMap { _, section -> UICollectionViewLayoutAttributes in
            let attrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
            attrs.frame = CGRect(
                x: collectionView.contentOffset.x,
                y: Self.timelineHeight + CGFloat(section) * (Self.sectionHeight + Self.verticalSpacing),
                width: Self.channelHeaderWidth,
                height: (section != snapshot.sectionIdentifiers.count - 1) ? Self.sectionHeight + Self.verticalSpacing : Self.sectionHeight
            )
            attrs.zIndex = 3
            return attrs
        }
        
        let timelineAttr = TimelineLayoutAttributes(forDecorationViewOfKind: ElementKind.timeline.rawValue, with: IndexPath(item: 0, section: 0))
        timelineAttr.frame = CGRect(
            x: Self.channelHeaderWidth + Self.horizontalSpacing,
            y: collectionView.contentOffset.y,
            width: dateInterval.duration * Self.scale,
            height: Self.timelineHeight
        )
        timelineAttr.dateInterval = dateInterval
        timelineAttr.zIndex = 1
        
        var decorationAttrs: [UICollectionViewLayoutAttributes] = [timelineAttr]
        if !snapshot.sectionIdentifiers.isEmpty, let verticalNowIndicatorAttr = verticalNowIndicatorAttr(dateInterval: dateInterval, in: collectionView) {
            decorationAttrs.append(verticalNowIndicatorAttr)
        }
        return LayoutData(layoutAttrs: layoutAttrs, supplementaryAttrs: headerAttrs, decorationAttrs: decorationAttrs, dateInterval: dateInterval)
    }
    
    private static func verticalNowIndicatorAttr(dateInterval: DateInterval, in collectionView: UICollectionView) -> UICollectionViewLayoutAttributes? {
        let nowDate = Date()
        if dateInterval.contains(nowDate) {
            let verticalNowIndicatorAttr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: ElementKind.verticalNowIndicator.rawValue, with: verticalNowIndicatorIndexPath)
            verticalNowIndicatorAttr.frame = CGRect(
                x: Self.channelHeaderWidth + Self.horizontalSpacing + nowDate.timeIntervalSince(dateInterval.start) * Self.scale - VerticalNowIndicatorView.width / 2,
                y: collectionView.contentOffset.y + Self.timelineHeight - VerticalNowIndicatorView.headerHeight,
                width: VerticalNowIndicatorView.width,
                height: max(VerticalNowIndicatorView.headerHeight + CGFloat(collectionView.numberOfSections) * (Self.sectionHeight + Self.verticalSpacing) - Self.verticalSpacing - collectionView.contentOffset.y, VerticalNowIndicatorView.headerHeight)
            )
            verticalNowIndicatorAttr.zIndex = 2
            return verticalNowIndicatorAttr
        }
        else {
            return nil
        }
    }
    
    private var focusedIndexPath: IndexPath? {
        guard let focusedCell = UIScreen.main.focusedView as? UICollectionViewCell else { return nil }
        return collectionView?.indexPath(for: focusedCell)
    }
    
    override init() {
        super.init()
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.invalidateLayout()
            }
            .store(in: &cancellables)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        
        if let collectionView = collectionView, let dataSource = collectionView.dataSource as? UICollectionViewDiffableDataSource<SRGChannel, SRGProgram> {
            layoutData = Self.layoutData(from: dataSource.snapshot(), in: collectionView)
        }
        else {
            layoutData = nil
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView, let layoutData = layoutData else { return .zero }
        return CGSize(
            width: Self.channelHeaderWidth + Self.horizontalSpacing + layoutData.dateInterval.duration * Self.scale + Self.trailingMargin,
            height: Self.timelineHeight + CGFloat(collectionView.numberOfSections) * Self.sectionHeight + max(CGFloat(collectionView.numberOfSections - 1), 0) * Self.verticalSpacing
        )
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutData = layoutData else { return nil }
        let layoutAttrs = layoutData.layoutAttrs.filter { $0.frame.intersects(rect) }
        let supplementaryAttrs = layoutData.supplementaryAttrs.filter { $0.frame.intersects(rect) }
        let decorationAttrs = layoutData.decorationAttrs.filter { $0.frame.intersects(rect) }
        return layoutAttrs + supplementaryAttrs + decorationAttrs
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutData?.layoutAttrs.first { $0.indexPath == indexPath }
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutData?.supplementaryAttrs.first { $0.indexPath == indexPath && $0.representedElementKind == elementKind }
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutData?.decorationAttrs.first { $0.indexPath == indexPath && $0.representedElementKind == elementKind }
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView,
              let focusedIndexPath = focusedIndexPath,
              let layoutAttr = layoutAttributesForItem(at: focusedIndexPath) else { return proposedContentOffset }
        let reservedWidth = Self.channelHeaderWidth + Self.horizontalSpacing
        let xOffset = layoutAttr.frame.minX - reservedWidth
        
        // If the currently focused item leading edge is obscured by the header, or if the item itself is larger than the
        // collection (considering its header), align the item at the leading layout boundary.
        if collectionView.contentOffset.x - xOffset > 0 || layoutAttr.frame.width + reservedWidth - collectionView.frame.width > 0 {
            return CGPoint(x: xOffset, y: proposedContentOffset.y)
        }
        // Otherwise just use the proposed position
        else {
            return proposedContentOffset
        }
    }
}

// MARK: Custom attributes

final class TimelineLayoutAttributes: UICollectionViewLayoutAttributes {
    var dateInterval: DateInterval?
}
