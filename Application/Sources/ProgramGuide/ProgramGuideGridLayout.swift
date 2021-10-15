//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

final class ProgramGuideGridLayout: UICollectionViewLayout {
    static let scale: CGFloat = constant(iOS: 328, tvOS: 368) / (60 * 60)
    static let sectionHeight: CGFloat = constant(iOS: 105, tvOS: 120)
    
    static let itemDuration: CGFloat = 3600
    
    var layoutAttrs: [UICollectionViewLayoutAttributes] = []
    
    static func maxNumberOfItemsForSections(in collectionView: UICollectionView) -> Int? {
        let numberOfItemsInSections = (0..<collectionView.numberOfSections).map { section in
            collectionView.numberOfItems(inSection: section)
        }
        return numberOfItemsInSections.max()
    }
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else { return }
        
        layoutAttrs = (0..<collectionView.numberOfSections).flatMap { section in
            return (0..<collectionView.numberOfItems(inSection: section)).map { item in
                let itemWidth = Self.scale * Self.itemDuration
                let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: section))
                attr.frame = CGRect(
                    x: CGFloat(item) * itemWidth,
                    y: CGFloat(section) * Self.sectionHeight,
                    width: itemWidth,
                    height: Self.sectionHeight
                )
                return attr
            }
        }
    }
    
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView,
              let maxNumberOfItems = Self.maxNumberOfItemsForSections(in: collectionView) else { return .zero }
        
        return CGSize(
            width: CGFloat(maxNumberOfItems) * Self.scale * Self.itemDuration,
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
