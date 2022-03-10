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
        case nowArrow
        case nowLine
    }
    
    static let decorationIndexPath = IndexPath(item: 0, section: 0)
    static let timelineHeight: CGFloat = constant(iOS: 40, tvOS: 60)
    static let timelinePadding: CGFloat = 1000
    static let channelHeaderWidth: CGFloat = 102
    static let horizontalSpacing: CGFloat = constant(iOS: 2, tvOS: 4)
    static let verticalSpacing: CGFloat = constant(iOS: 3, tvOS: 6)
    
    private struct LayoutData {
        let layoutAttrs: [UICollectionViewLayoutAttributes]
        let supplementaryAttrs: [UICollectionViewLayoutAttributes]
        let decorationAttrs: [UICollectionViewLayoutAttributes]
        let dateInterval: DateInterval
    }
    
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
        return Calendar.srgDefault.date(byAdding: dateComponent, to: startDate)!
    }
    
    private static func dateInterval(from snapshot: NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>) -> DateInterval? {
        guard let startDate = startDate(from: snapshot) else { return nil }
        return DateInterval(start: startDate, end: endDate(from: startDate))
    }
    
    private static func frame(from startDate: Date, to endDate: Date, in dateInterval: DateInterval, forSection section: Int, collectionView: UICollectionView) -> CGRect {
        // Adjust the frame of items which would be partially visible otherwise. Two different behaviors are implemented
        // for iOS and tvOS:
        //  - On iOS items partially visible on the left are adjusted to ensure their content is always visible.
        //  - On tvOS items partially visible on the left and / or right are adjusted. This ensures their content
        //    is always visible and that focus navigation is horizontally stable on the left of the collection. Items
        //    coming from the right start in a shrinked state, unlike iOS, but this makes focus navigation on the right
        //    of the collection a bit more horizontally stable than if this wasn't done. Not all horizontal motions
        //    can be eliminated, though, probably because the focus engine attempts to have items visible within a smaller
        //    invisible frame in the collection.
        let visibleFrame = CGRect(
            x: collectionView.contentOffset.x + channelHeaderWidth,
            y: 0,
            width: constant(iOS: .greatestFiniteMagnitude, tvOS: max(collectionView.frame.width - channelHeaderWidth, 0)),
            height: .greatestFiniteMagnitude
        )
        let frame = CGRect(
            x: xPosition(at: startDate, in: dateInterval),
            y: timelineHeight + CGFloat(section) * (sectionHeight + verticalSpacing),
            width: max(endDate.timeIntervalSince(startDate) * scale - horizontalSpacing, 0),
            height: sectionHeight
        )
        return frame.intersects(visibleFrame) ? frame.intersection(visibleFrame) : frame
    }
    
    private static func layoutData(from snapshot: NSDiffableDataSourceSnapshot<ProgramGuideDailyViewModel.Section, ProgramGuideDailyViewModel.Item>, in collectionView: UICollectionView) -> LayoutData? {
        guard let dateInterval = dateInterval(from: snapshot) else { return nil }
        let layoutAttrs = snapshot.sectionIdentifiers.enumeratedFlatMap { channel, section in
            return snapshot.itemIdentifiers(inSection: channel).enumeratedMap { item, index -> UICollectionViewLayoutAttributes in
                let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: section))
                if let program = item.program {
                    attrs.frame = frame(from: program.startDate, to: program.endDate, in: dateInterval, forSection: section, collectionView: collectionView)
                }
                else {
                    attrs.frame = frame(from: dateInterval.start, to: dateInterval.end, in: dateInterval, forSection: section, collectionView: collectionView)
                }
                return attrs
            }
        }
        let headerAttrs = snapshot.sectionIdentifiers.enumeratedMap { _, section -> UICollectionViewLayoutAttributes in
            let attrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
            attrs.frame = CGRect(
                x: collectionView.contentOffset.x,
                y: timelineHeight + CGFloat(section) * (sectionHeight + verticalSpacing),
                width: channelHeaderWidth,
                height: (section != snapshot.sectionIdentifiers.count - 1) ? sectionHeight + verticalSpacing : sectionHeight
            )
            attrs.zIndex = 2
            return attrs
        }
        
        let timelineAttr = TimelineLayoutAttributes(forDecorationViewOfKind: ElementKind.timeline.rawValue, with: IndexPath(item: 0, section: 0))
        timelineAttr.frame = CGRect(
            x: -timelinePadding,
            y: collectionView.contentOffset.y,
            width: timelinePadding + dateInterval.duration * scale,
            height: timelineHeight
        )
        timelineAttr.dateInterval = dateInterval
        timelineAttr.zIndex = 3
        
        let nowDate = Date()
        var decorationAttrs: [UICollectionViewLayoutAttributes] = [timelineAttr]
        if !snapshot.sectionIdentifiers.isEmpty, dateInterval.contains(nowDate) {
            let nowHeadAttr = nowArrowAttr(at: nowDate, in: dateInterval, collectionView: collectionView)
            decorationAttrs.append(nowHeadAttr)
            
            let nowLineAttr = nowLineAttr(at: nowDate, in: dateInterval, collectionView: collectionView)
            decorationAttrs.append(nowLineAttr)
        }
        return LayoutData(layoutAttrs: layoutAttrs, supplementaryAttrs: headerAttrs, decorationAttrs: decorationAttrs, dateInterval: dateInterval)
    }
    
    private static func xPosition(at date: Date, in dateInterval: DateInterval) -> CGFloat {
        return channelHeaderWidth + horizontalSpacing + date.timeIntervalSince(dateInterval.start) * scale
    }
    
    private static func nowXPosition(at date: Date, in dateInterval: DateInterval) -> CGFloat {
        return xPosition(at: date, in: dateInterval) - NowArrowView.size.width / 2
    }
    
    private static func nowArrowAttr(at date: Date, in dateInterval: DateInterval, collectionView: UICollectionView) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: ElementKind.nowArrow.rawValue, with: decorationIndexPath)
        attr.frame = CGRect(
            x: nowXPosition(at: date, in: dateInterval),
            y: collectionView.contentOffset.y + timelineHeight - NowArrowView.size.height,
            width: NowArrowView.size.width,
            height: NowArrowView.size.height
        )
        attr.zIndex = 4
        return attr
    }
    
    private static func nowLineAttr(at date: Date, in dateInterval: DateInterval, collectionView: UICollectionView) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: ElementKind.nowLine.rawValue, with: decorationIndexPath)
        attr.frame = CGRect(
            x: nowXPosition(at: date, in: dateInterval),
            y: collectionView.contentOffset.y + timelineHeight,
            width: NowArrowView.size.width,
            height: max(CGFloat(collectionView.numberOfSections) * (sectionHeight + verticalSpacing) - verticalSpacing - collectionView.contentOffset.y, 0)
        )
        attr.zIndex = 1
        return attr
    }
    
    private var focusedIndexPath: IndexPath? {
        guard let focusedCell = UIScreen.main.focusedView as? UICollectionViewCell else { return nil }
        return collectionView?.indexPath(for: focusedCell)
    }
    
    override init() {
        super.init()
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
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
