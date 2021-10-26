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
        let dateInterval: DateInterval
    }
    
    private static let scale: CGFloat = constant(iOS: 328, tvOS: 368) / (60 * 60)
    private static let sectionHeight: CGFloat = constant(iOS: 105, tvOS: 120)
    
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
    
    private static func data(from snapshot: NSDiffableDataSourceSnapshot<SRGChannel, SRGProgram>) -> Data? {
        guard let dateInterval = Self.dateInterval(from: snapshot) else { return nil }
        let layoutAttrs = snapshot.sectionIdentifiers.enumeratedFlatMap { channel, section in
            return snapshot.itemIdentifiers(inSection: channel).enumeratedMap { program, item -> UICollectionViewLayoutAttributes in
                let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: section))
                attr.frame = CGRect(
                    x: program.startDate.timeIntervalSince(dateInterval.start) * Self.scale,
                    y: CGFloat(section) * Self.sectionHeight,
                    width: program.endDate.timeIntervalSince(program.startDate) * Self.scale,
                    height: Self.sectionHeight
                )
                return attr
            }
        }
        return Data(layoutAttrs: layoutAttrs, dateInterval: dateInterval)
    }
    
    override func prepare() {
        super.prepare()
        
        if let dataSource = collectionView?.dataSource as? UICollectionViewDiffableDataSource<SRGChannel, SRGProgram> {
            data = Self.data(from: dataSource.snapshot())
        }
        else {
            data = nil
        }
    }
    
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView, let data = data else { return .zero }
        return CGSize(
            width: data.dateInterval.duration * Self.scale,
            height: CGFloat(collectionView.numberOfSections) * Self.sectionHeight
        )
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return data?.layoutAttrs.filter { $0.frame.intersects(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return data?.layoutAttrs.first { $0.indexPath == indexPath }
    }
}
