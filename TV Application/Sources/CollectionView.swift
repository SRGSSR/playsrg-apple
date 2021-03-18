//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  Used as magic value (similar to NSNull.null in Objective-C) for default nearest view controller resolution.
 */
fileprivate final class NearestViewController: UIViewController {
    static let shared = NearestViewController()
}

extension CollectionView {
    func synchronizeTabBarScrolling(with viewController: UIViewController? = nil) -> CollectionView {
        var collectionView = self
        collectionView.parentViewController = viewController ?? NearestViewController.shared
        return collectionView
    }
}

extension CollectionView {
    func synchronizeSearchScrolling(with controller: UISearchController?) -> CollectionView {
        var collectionView = self
        collectionView.parentSearchController = controller
        return collectionView
    }
}

/**
 *  Collection row.
 */
struct CollectionRow<Section: Hashable, Item: Hashable>: Hashable {
    /// Section.
    let section: Section
    /// Items contained within the section.
    let items: [Item]
}

/**
 *  A `UICollectionView`-powered SwiftUI collection, whose cells are provided as SwiftUI views.
 */
struct CollectionView<Section: Hashable, Item: Hashable, Cell: View, SupplementaryView: View>: UIViewRepresentable {
    /**
     *  View coordinator.
     */
    class Coordinator: NSObject, UICollectionViewDelegate {
        fileprivate typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
        
        /// Data source for the collection view.
        fileprivate var dataSource: DataSource? = nil
        
        /// Provider for the section layout.
        fileprivate var sectionLayoutProvider: ((Int, Section, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection)?
        
        /// Hash of the data represented by the data source. Provides for a cheap way of checking when data changes.
        fileprivate var rowsHash: Int? = nil
        
        /// Registered view kinds for supplementary views.
        fileprivate var registeredSupplementaryViewKinds: [String] = []
        
        /// Whether cells are currently focusable.
        fileprivate var focusable = false
        
        public func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
            return focusable
        }
    }
    
    /// Data displayed by the collection view.
    let rows: [CollectionRow<Section, Item>]
    
    /// Provider for the section layout.
    let sectionLayoutProvider: (Int, Section, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection
    
    /// Cell view builder.
    let cell: (IndexPath, Section, Item) -> Cell
    
    /// Supplementary view builder.
    let supplementaryView: (String, IndexPath, Section, Item) -> SupplementaryView
    
    /// The view controller (child of a tab bar controller) which should be moved when scrolling occurs.
    fileprivate weak var parentViewController: UIViewController? = nil
    
    /// The parent search controller to move the collection with, if any.
    fileprivate weak var parentSearchController: UISearchController? = nil
    
    /**
     *  Remove item duplicates. As items can be moved between sections no item must appear multiple times, whether in
     *  the same row or in different rows.
     *
     *  Idea borrowed from https://www.hackingwithswift.com/example-code/language/how-to-remove-duplicate-items-from-an-array
     */
    private static func removeDuplicates(in rows: [CollectionRow<Section, Item>]) -> [CollectionRow<Section, Item>] {
        var addedItems = [Item: Bool]()
        var cleanedRows = [CollectionRow<Section, Item>]()
        for row in rows {
            let cleanedRow = CollectionRow(section: row.section, items: row.items.filter {
                let isNew = addedItems.updateValue(true, forKey: $0) == nil
                if !isNew {
                    PlayLogWarning(category: "collection", message: "A duplicate item has been removed: \($0)")
                }
                return isNew
            })
            cleanedRows.append(cleanedRow)
        }
        return cleanedRows
    }
    
    /**
     *  Create a collection view displaying the specified data with cells delivered by the provided builder.
     */
    init(rows: [CollectionRow<Section, Item>],
         sectionLayoutProvider: @escaping (Int, Section, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection,
         @ViewBuilder cell: @escaping (IndexPath, Section, Item) -> Cell,
         @ViewBuilder supplementaryView: @escaping (String, IndexPath, Section, Item) -> SupplementaryView) {
        self.rows = Self.removeDuplicates(in: rows)
        self.sectionLayoutProvider = sectionLayoutProvider
        self.cell = cell
        self.supplementaryView = supplementaryView
    }
    
    /**
     *  Create the data source snapshot corresponding to the data.
     */
    private func snapshot() -> NSDiffableDataSourceSnapshot<Section, Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        for row in rows {
            snapshot.appendSections([row.section])
            snapshot.appendItems(row.items, toSection: row.section)
        }
        return snapshot
    }
    
    private func layout(context: Context) -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let coordinator = context.coordinator
            let section = coordinator.dataSource!.snapshot().sectionIdentifiers[sectionIndex]
            return coordinator.sectionLayoutProvider!(sectionIndex, section, layoutEnvironment)
        }
    }
    
    private func reloadData(in collectionView: UICollectionView, context: Context, animated: Bool = false) {
        let coordinator = context.coordinator
        coordinator.sectionLayoutProvider = self.sectionLayoutProvider
        
        guard let dataSource = coordinator.dataSource else { return }
        
        let rowsHash = rows.hashValue
        if coordinator.rowsHash != rowsHash {
            DispatchQueue.global(qos: .userInteractive).async {
                dataSource.apply(snapshot(), animatingDifferences: animated) {
                    coordinator.focusable = true
                    collectionView.setNeedsFocusUpdate()
                    collectionView.updateFocusIfNeeded()
                    coordinator.focusable = false
                }
            }
            coordinator.rowsHash = rowsHash
        }
    }
    
    // MARK: - UIViewRepresentable implementation
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let cellIdentifier = "hostCell"
        let supplementaryViewIdentifier = "hostSupplementaryView"
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout(context: context))
        collectionView.delegate = context.coordinator
        collectionView.register(HostCollectionViewCell<Cell>.self, forCellWithReuseIdentifier: cellIdentifier)
        
        let dataSource = Coordinator.DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let snapshot = context.coordinator.dataSource!.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            
            let hostCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! HostCollectionViewCell<Cell>
            hostCell.content = cell(indexPath, section, item)
            return hostCell
        }
        context.coordinator.dataSource = dataSource
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            let coordinator = context.coordinator
            if !coordinator.registeredSupplementaryViewKinds.contains(kind) {
                collectionView.register(HostSupplementaryView<SupplementaryView>.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: supplementaryViewIdentifier)
                coordinator.registeredSupplementaryViewKinds.append(kind)
            }
            
            let snapshot = coordinator.dataSource!.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
            
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: supplementaryViewIdentifier, for: indexPath) as! HostSupplementaryView<SupplementaryView>
            view.content = supplementaryView(kind, indexPath, section, item)
            return view
        }
        
        reloadData(in: collectionView, context: context)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        if parentViewController == NearestViewController.shared {
            uiView.play_nearestViewController?.tabBarObservedScrollView = uiView
        }
        else {
            parentViewController?.tabBarObservedScrollView = uiView
        }
        parentSearchController?.searchControllerObservedScrollView = uiView
        
        reloadData(in: uiView, context: context, animated: true)
    }
}
