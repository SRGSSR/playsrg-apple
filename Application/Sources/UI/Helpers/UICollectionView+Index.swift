//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

protocol Indexable {
    /// The title of the index entry corresponding to the section
    var indexTitle: String { get }
}

/**
 *  There is no built-in support for index titles with diffable data sources, but this can be fixed with a lightweight
 *  subclass, see https://developer.apple.com/forums/thread/117727.
 *
 *  This approach works both for iOS and tvOS.
 */
class IndexedCollectionViewDiffableDataSource<Section, Item>: UICollectionViewDiffableDataSource<Section, Item> where Section: Hashable & Indexable, Item: Hashable {
    private let minimumIndexTitlesCount: Int

    init(collectionView: UICollectionView, minimumIndexTitlesCount: Int, cellProvider: @escaping CellProvider) {
        self.minimumIndexTitlesCount = max(minimumIndexTitlesCount, 2)
        super.init(collectionView: collectionView, cellProvider: cellProvider)
    }

    override convenience init(collectionView: UICollectionView, cellProvider: @escaping CellProvider) {
        self.init(collectionView: collectionView, minimumIndexTitlesCount: 2, cellProvider: cellProvider)
    }

    override func indexTitles(for _: UICollectionView) -> [String]? {
        let sectionIdentifiers = snapshot().sectionIdentifiers
        return (sectionIdentifiers.count >= minimumIndexTitlesCount) ? sectionIdentifiers.map(\.indexTitle) : nil
    }

    override func collectionView(_: UICollectionView, indexPathForIndexTitle _: String, at index: Int) -> IndexPath {
        return IndexPath(row: 0, section: index)
    }
}

#if os(iOS)
    /**
     *  Index titles have been made available for iOS 14+, but they suffer from two issues in comparison to the
     *  `UITableView` API:
     *    - Lack of proper reload API if the data is not known initially.
     *    - Lack of color customization API.
     *  This is a known limitation (see https://developer.apple.com/forums/thread/6565859 but fortunately it is
     *  easy to fill these gaps.
     *
     *  No such API is required on tvOS, as the index title API is called on demand when scrolling fast. Colors
     *  also look fine.
     */
    extension UICollectionView {
        private func sectionIndexBar() -> UIView? {
            return subviews.first { view in
                NSStringFromClass(type(of: view)).contains("I24n4d23ex5Bar7A6cc86ess98oryV6i6ew".unobfuscated())
            }
        }

        private static func setColor(_ color: UIColor?, on view: UIView, selector: Selector) {
            if view.responds(to: selector) {
                view.perform(selector, with: color)
            }
        }

        private static func setIndexColor(_ color: UIColor?, on view: UIView) {
            setColor(color, on: view, selector: NSSelectorFromString("s6et72I3nde3xC3ol84o3r:9".unobfuscated()))
        }

        private static func setIndexBackgroundColor(_ color: UIColor?, on view: UIView) {
            setColor(color, on: view, selector: NSSelectorFromString("s3e4t5No6nTr57ac5775ki7ngB765a5ckg5ro89und09Col67or:76".unobfuscated()))
        }

        func setSectionBarAppearance(indexColor: UIColor?, indexBackgroundColor: UIColor?) {
            if let indexBar = sectionIndexBar() {
                Self.setIndexColor(indexColor, on: indexBar)
                Self.setIndexBackgroundColor(indexBackgroundColor, on: indexBar)
            }
        }

        func reloadSectionIndexBar() {
            let selector = NSSelectorFromString("9_r5e44lo679ad92S3e4ct56i78on89Ind45e6x7T88i9tl4es".unobfuscated())
            if responds(to: selector) {
                perform(selector)
            }
        }
    }
#endif
