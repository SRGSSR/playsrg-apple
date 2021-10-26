//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

final class ProgramGuideGridLayout: UICollectionViewLayout {
    static let scale: CGFloat = constant(iOS: 328, tvOS: 368) / (60 * 60)
    static let sectionHeight: CGFloat = constant(iOS: 105, tvOS: 120)
    
    var layoutAttrs: [UICollectionViewLayoutAttributes] = []
    var dateInterval: DateInterval?
    
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
    
    override func prepare() {
        super.prepare()
        
        guard let dataSource = collectionView?.dataSource as? UICollectionViewDiffableDataSource<SRGChannel, SRGProgram> else {
            dateInterval = nil
            layoutAttrs = []
            return
        }
        let snapshot = dataSource.snapshot()
        
        dateInterval = Self.dateInterval(from: snapshot)
        guard let dateInterval = dateInterval else {
            layoutAttrs = []
            return
        }
        
        layoutAttrs = snapshot.sectionIdentifiers.enumeratedFlatMap { channel, section in
            return snapshot.itemIdentifiers(inSection: channel).enumeratedMap { program, item in
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
    }
    
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView, let dateInterval = dateInterval else { return .zero }
        return CGSize(
            width: dateInterval.duration * Self.scale,
            height: CGFloat(collectionView.numberOfSections) * Self.sectionHeight
        )
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return layoutAttrs.filter { $0.frame.intersects(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttrs.first { $0.indexPath == indexPath }
    }
}
