//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import UIKit

// MARK: Layout

/**
 *  ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 *  │                                                                                                                                    │
 *  │                                                    Timeline (decoration)                                                           │
 *  │───────────────┬┬─────────────────────────────────────────────────────────┬┬────────────────────────────────┬┬────────────┬────────┬┤
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
    static let timelineHeight: CGFloat = constant(iOS: 40, tvOS: 60)
    static let channelHeaderWidth: CGFloat = 102
    static let horizontalSpacing: CGFloat = constant(iOS: 2, tvOS: 4)
    
    private struct LayoutData {
        let layoutAttrs: [UICollectionViewLayoutAttributes]
        let supplementaryAttrs: [UICollectionViewLayoutAttributes]
        let decorationAttrs: [UICollectionViewLayoutAttributes]
        let dateInterval: DateInterval
    }
    
    private static let verticalSpacing: CGFloat = constant(iOS: 3, tvOS: 6)
    private static let scale: CGFloat = constant(iOS: 430, tvOS: 900) / (60 * 60)
    private static let sectionHeight: CGFloat = constant(iOS: 105, tvOS: 120)
    private static let trailingMargin: CGFloat = 10
    
    private var layoutData: LayoutData?
    private var cancellables = Set<AnyCancellable>()
    
    private static func startDate(from snapshot: NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>) -> Date? {
        guard let section = snapshot.sectionIdentifiers.first(where: { section in
            return !snapshot.itemIdentifiers(inSection: section).isEmpty
        }) else { return nil }
        return snapshot.itemIdentifiers(inSection: section).first?.day.date
    }
    
    private static func endDate(from startDate: Date) -> Date {
        let dateComponent = DateComponents(day: 1, hour: 3)
        return Calendar.current.date(byAdding: dateComponent, to: startDate)!
    }
    
    private static func dateInterval(from snapshot: NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>) -> DateInterval? {
        guard let startDate = startDate(from: snapshot) else { return nil }
        return DateInterval(start: startDate, end: endDate(from: startDate))
    }
    
    private static func frame(from startDate: Date, to endDate: Date, in dateInterval: DateInterval, forSection section: Int, atOffset contentOffset: CGPoint) -> CGRect {
        let offsetX = contentOffset.x + Self.channelHeaderWidth
        var x = Self.channelHeaderWidth + Self.horizontalSpacing + startDate.timeIntervalSince(dateInterval.start) * Self.scale
        var width = max(endDate.timeIntervalSince(startDate) * Self.scale - Self.horizontalSpacing, 0)
        
        // To display left labels in cells, and on tvOS, limited layout moves when focus changes, set left visible cells fully visible in the grid.
        if x + width >= offsetX && x < offsetX {
            let diff = offsetX - x
            x += diff
            width -= diff
        }
        
        return CGRect(
            x: x,
            y: Self.timelineHeight + CGFloat(section) * (Self.sectionHeight + Self.verticalSpacing),
            width: max(width, 0),
            height: Self.sectionHeight
        )
    }
    
    private static func layoutData(from snapshot: NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>, in collectionView: UICollectionView) -> LayoutData? {
        guard let dateInterval = dateInterval(from: snapshot) else { return nil }
        let layoutAttrs = snapshot.sectionIdentifiers.enumeratedFlatMap { channel, section in
            return snapshot.itemIdentifiers(inSection: channel).enumeratedMap { item, index -> UICollectionViewLayoutAttributes in
                let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: section))
                if let program = item.program {
                    attrs.frame = frame(from: program.startDate, to: program.endDate, in: dateInterval, forSection: section, atOffset: collectionView.contentOffset)
                }
                else {
                    attrs.frame = frame(from: dateInterval.start, to: dateInterval.end, in: dateInterval, forSection: section, atOffset: collectionView.contentOffset)
                }
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
            attrs.zIndex = 2
            return attrs
        }
        
        let timelineAttr = TimelineLayoutAttributes(forDecorationViewOfKind: ElementKind.timeline.rawValue, with: IndexPath(item: 0, section: 0))
        timelineAttr.frame = CGRect(
            x: 0,
            y: collectionView.contentOffset.y,
            width: dateInterval.duration * Self.scale,
            height: Self.timelineHeight
        )
        timelineAttr.dateInterval = dateInterval
        timelineAttr.zIndex = 3
        
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
            verticalNowIndicatorAttr.zIndex = 1
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
        
        if let collectionView = collectionView, let dataSource = collectionView.dataSource as? UICollectionViewDiffableDataSource<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item> {
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

// MARK: Layout calculations

extension ProgramGuideGridLayout {
    private static func dateInterval(for day: SRGDay) -> DateInterval {
        let startDate = day.date
        return DateInterval(start: startDate, end: endDate(from: startDate))
    }
    
    private static func safeXOffset(_ xOffset: CGFloat, in collectionView: UICollectionView) -> CGFloat {
        let maxXOffset = max(collectionView.contentSize.width - collectionView.frame.width
            + collectionView.adjustedContentInset.left + collectionView.adjustedContentInset.right, 0)
        return xOffset.clamped(to: 0...maxXOffset)
    }
    
    private static func safeYOffset(_ yOffset: CGFloat, in collectionView: UICollectionView) -> CGFloat {
        let maxYOffset = max(collectionView.contentSize.height - collectionView.frame.height
            + collectionView.adjustedContentInset.top + collectionView.adjustedContentInset.bottom, 0)
        return yOffset.clamped(to: 0...maxYOffset)
    }
    
    static func date(centeredAtXOffset xOffset: CGFloat, in collectionView: UICollectionView, day: SRGDay) -> Date? {
        let dateInterval = dateInterval(for: day)
        let gridWidth = max(collectionView.frame.width - channelHeaderWidth, 0)
        let date = dateInterval.start.addingTimeInterval(safeXOffset(xOffset + gridWidth / 2.0, in: collectionView) / scale)
        return dateInterval.contains(date) ? date : nil
    }
    
    static func sectionIndex(atYOffset yOffset: CGFloat, in collectionView: UICollectionView) -> Int {
        return Int(safeYOffset(yOffset, in: collectionView) / (sectionHeight + verticalSpacing))
    }
    
    static func xOffset(centeringDate date: Date, in collectionView: UICollectionView, day: SRGDay) -> CGFloat? {
        guard collectionView.contentSize != .zero else { return nil }
        let dateInterval = dateInterval(for: day)
        guard dateInterval.contains(date) else { return nil }
        let gridWidth = max(collectionView.frame.width - channelHeaderWidth, 0)
        return safeXOffset(date.timeIntervalSince(dateInterval.start) * scale - gridWidth / 2.0, in: collectionView)
    }
    
    static func yOffset(forSectionIndex sectionIndex: Int, in collectionView: UICollectionView) -> CGFloat? {
        guard collectionView.contentSize != .zero else { return nil }
        return safeYOffset(CGFloat(sectionIndex) * (sectionHeight + verticalSpacing), in: collectionView)
    }
}

// MARK: Custom attributes

final class TimelineLayoutAttributes: UICollectionViewLayoutAttributes {
    var dateInterval: DateInterval?
}
