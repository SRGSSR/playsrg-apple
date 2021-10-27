//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import UIKit

final class ProgramGuideGridLayout: UICollectionViewLayout {
    private struct LayoutData {
        let layoutAttrs: [UICollectionViewLayoutAttributes]
        let supplementaryLayoutAttrs: [UICollectionViewLayoutAttributes]
        let dateInterval: DateInterval
    }
    
    private static let horizontalSpacing: CGFloat = constant(iOS: 2, tvOS: 4)
    private static let verticalSpacing: CGFloat = constant(iOS: 3, tvOS: 6)
    private static let scale: CGFloat = constant(iOS: 650, tvOS: 900) / (60 * 60)
    private static let sectionHeight: CGFloat = constant(iOS: 105, tvOS: 160)
    private static let channelHeaderWidth: CGFloat = constant(iOS: 130, tvOS: 220)
    private static let trailingMargin: CGFloat = 10
    
    private var layoutData: LayoutData?
    
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
        guard let dateInterval = Self.dateInterval(from: snapshot) else { return nil }
        let layoutAttrs = snapshot.sectionIdentifiers.enumeratedFlatMap { channel, section in
            return snapshot.itemIdentifiers(inSection: channel).enumeratedMap { program, item -> UICollectionViewLayoutAttributes in
                let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: section))
                attrs.frame = CGRect(
                    x: Self.channelHeaderWidth + Self.horizontalSpacing + program.startDate.timeIntervalSince(dateInterval.start) * Self.scale,
                    y: CGFloat(section) * (Self.sectionHeight + Self.verticalSpacing),
                    width: max(program.endDate.timeIntervalSince(program.startDate) * Self.scale - Self.horizontalSpacing, 0),
                    height: Self.sectionHeight
                )
                return attrs
            }
        }
        let supplementaryLayoutAttrs = snapshot.sectionIdentifiers.enumeratedMap { _, section -> UICollectionViewLayoutAttributes in
            let attrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
            attrs.frame = CGRect(
                x: collectionView.contentOffset.x,
                y: CGFloat(section) * (Self.sectionHeight + Self.verticalSpacing),
                width: Self.channelHeaderWidth,
                height: Self.sectionHeight + Self.verticalSpacing
            )
            attrs.zIndex = 1
            return attrs
        }
        return LayoutData(layoutAttrs: layoutAttrs, supplementaryLayoutAttrs: supplementaryLayoutAttrs, dateInterval: dateInterval)
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
            width: layoutData.dateInterval.duration * Self.scale + Self.channelHeaderWidth + Self.horizontalSpacing + Self.trailingMargin,
            height: CGFloat(collectionView.numberOfSections) * Self.sectionHeight + max(CGFloat(collectionView.numberOfSections - 1), 0) * Self.verticalSpacing
        )
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutData = layoutData else { return nil }
        let layoutAttrs = layoutData.layoutAttrs.filter { $0.frame.intersects(rect) }
        let supplementaryLayoutAttrs = layoutData.supplementaryLayoutAttrs.filter { $0.frame.intersects(rect) }
        return layoutAttrs + supplementaryLayoutAttrs
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutData?.layoutAttrs.first { $0.indexPath == indexPath }
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutData?.supplementaryLayoutAttrs.first { $0.indexPath == indexPath && $0.representedElementKind == elementKind }
    }
}
