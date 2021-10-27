//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import UIKit

final class ProgramGuideGridLayout: UICollectionViewLayout {
    private struct Data {
        let layoutAttrs: [UICollectionViewLayoutAttributes]
        let supplementaryLayoutAttrs: [UICollectionViewLayoutAttributes]
        let dateInterval: DateInterval
    }
    
    private static let horizontalSpacing: CGFloat = 2
    private static let verticalSpacing: CGFloat = 3
    private static let scale: CGFloat = constant(iOS: 650, tvOS: 750) / (60 * 60)
    private static let sectionHeight: CGFloat = constant(iOS: 105, tvOS: 120)
    private static let channelHeaderWidth: CGFloat = 100
    
    private var data: Data?
    
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
    
    private static func data(from snapshot: NSDiffableDataSourceSnapshot<SRGChannel, SRGProgram>, in collectionView: UICollectionView) -> Data? {
        guard let dateInterval = Self.dateInterval(from: snapshot) else { return nil }
        let layoutAttrs = snapshot.sectionIdentifiers.enumeratedFlatMap { channel, section in
            return snapshot.itemIdentifiers(inSection: channel).enumeratedMap { program, item -> UICollectionViewLayoutAttributes in
                let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: section))
                attrs.frame = CGRect(
                    x: Self.channelHeaderWidth + program.startDate.timeIntervalSince(dateInterval.start) * Self.scale,
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
        return Data(layoutAttrs: layoutAttrs, supplementaryLayoutAttrs: supplementaryLayoutAttrs, dateInterval: dateInterval)
    }
    
    override func prepare() {
        super.prepare()
        
        if let collectionView = collectionView, let dataSource = collectionView.dataSource as? UICollectionViewDiffableDataSource<SRGChannel, SRGProgram> {
            data = Self.data(from: dataSource.snapshot(), in: collectionView)
        }
        else {
            data = nil
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView, let data = data else { return .zero }
        return CGSize(
            width: data.dateInterval.duration * Self.scale + Self.channelHeaderWidth,
            height: CGFloat(collectionView.numberOfSections) * Self.sectionHeight + max(CGFloat(collectionView.numberOfSections - 1), 0) * Self.verticalSpacing
        )
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let data = data else { return nil }
        let layoutAttrs = data.layoutAttrs.filter { $0.frame.intersects(rect) }
        let supplementaryLayoutAttrs = data.supplementaryLayoutAttrs.filter { $0.frame.intersects(rect) }
        return layoutAttrs + supplementaryLayoutAttrs
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return data?.layoutAttrs.first { $0.indexPath == indexPath }
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return data?.supplementaryLayoutAttrs.first { $0.indexPath == indexPath && $0.representedElementKind == elementKind }
    }
}
