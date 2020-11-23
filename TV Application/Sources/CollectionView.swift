//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

extension CollectionView {
    func synchronizeParentTabScrolling() -> CollectionView {
        var collectionView = self
        collectionView.parentTabScrollingEnabled = true
        return collectionView
    }
}

// See https://stackoverflow.com/questions/61552497/uitableviewheaderfooterview-with-swiftui-content-getting-automatic-safe-area-ins
extension UIHostingController {
    convenience public init(rootView: Content, ignoreSafeArea: Bool) {
        self.init(rootView: rootView)
        
        if ignoreSafeArea {
            disableSafeArea()
        }
    }
    
    func disableSafeArea() {
        guard let viewClass = object_getClass(view) else { return }
        
        let viewSubclassName = String(cString: class_getName(viewClass)).appending("_IgnoreSafeArea")
        if let viewSubclass = NSClassFromString(viewSubclassName) {
            object_setClass(view, viewSubclass)
        }
        else {
            guard let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String else { return }
            guard let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0) else { return }
            
            if let method = class_getInstanceMethod(UIView.self, #selector(getter: UIView.safeAreaInsets)) {
                let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in
                    return .zero
                }
                class_addMethod(viewSubclass, #selector(getter: UIView.safeAreaInsets), imp_implementationWithBlock(safeAreaInsets), method_getTypeEncoding(method))
            }
            
            objc_registerClassPair(viewSubclass)
            object_setClass(view, viewSubclass)
        }
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
     *  `UICollectionView` cell hosting a `SwiftUI` view.
     */
    private class HostCell: UICollectionViewCell {
        private var hostController: UIHostingController<Cell>?
        
        override func prepareForReuse() {
            if let hostView = hostController?.view {
                hostView.removeFromSuperview()
            }
            hostController = nil
        }
        
        var hostedCell: Cell? {
            willSet {
                // Creating a `UIHostingController` is cheap.
                guard let view = newValue else { return }
                hostController = UIHostingController(rootView: view, ignoreSafeArea: true)
                if let hostView = hostController?.view {
                    hostView.frame = contentView.bounds
                    hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    contentView.addSubview(hostView)
                }
            }
        }
    }
    
    private class HostSupplementaryView: UICollectionReusableView {
        private var hostController: UIHostingController<SupplementaryView>?
        
        override func prepareForReuse() {
            if let hostView = hostController?.view {
                hostView.removeFromSuperview()
            }
            hostController = nil
        }
        
        var hostedSupplementaryView: SupplementaryView? {
            willSet {
                // Creating a `UIHostingController` is cheap.
                guard let view = newValue else { return }
                hostController = UIHostingController(rootView: view, ignoreSafeArea: true)
                if let hostView = hostController?.view {
                    hostView.frame = self.bounds
                    hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    addSubview(hostView)
                }
            }
        }
    }
    
    /**
     *  View coordinator.
     */
    class Coordinator: NSObject, UICollectionViewDelegate {
        fileprivate typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
        
        /// Data source for the collection view.
        fileprivate var dataSource: DataSource? = nil
        
        /// Provider for the section layout.
        fileprivate var sectionLayoutProvider: ((Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection)?
        
        /// Hash of the data represented by the data source. Provides for a cheap way of checking when data changes.
        fileprivate var rowsHash: Int? = nil
        
        /// Registered view kinds for supplementary views.
        fileprivate var registeredSupplementaryViewKinds: [String] = []
        
        /// Whether cells are currently focusable.
        fileprivate var focusable: Bool = false
        
        public func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
            return focusable
        }
    }
    
    /// Data displayed by the collection view.
    let rows: [CollectionRow<Section, Item>]
    
    /// Provider for the section layout.
    let sectionLayoutProvider: (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection
    
    /// Cell view builder.
    let cell: (IndexPath, Item) -> Cell
    
    /// Supplementary view builder.
    let supplementaryView: (String, IndexPath) -> SupplementaryView
    
    /// If `true`, tabs move in sync with the collection.
    fileprivate var parentTabScrollingEnabled: Bool = false
    
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
                addedItems.updateValue(true, forKey: $0) == nil
            })
            cleanedRows.append(cleanedRow)
        }
        return cleanedRows
    }
    
    /**
     *  Create a collection view displaying the specified data with cells delivered by the provided builder.
     */
    init(rows: [CollectionRow<Section, Item>],
         sectionLayoutProvider: @escaping (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection,
         @ViewBuilder cell: @escaping (IndexPath, Item) -> Cell,
         @ViewBuilder supplementaryView: @escaping (String, IndexPath) -> SupplementaryView) {
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
            return context.coordinator.sectionLayoutProvider!(sectionIndex, layoutEnvironment)
        }
    }
    
    private func reloadData(in collectionView: UICollectionView, context: Context, animated: Bool = false) {
        let coordinator = context.coordinator
        coordinator.sectionLayoutProvider = self.sectionLayoutProvider
        
        guard let dataSource = coordinator.dataSource else { return }
        
        let rowsHash = rows.hashValue
        if coordinator.rowsHash != rowsHash {
            dataSource.apply(snapshot(), animatingDifferences: animated) {
                coordinator.focusable = true
                collectionView.setNeedsFocusUpdate()
                collectionView.updateFocusIfNeeded()
                coordinator.focusable = false
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
        collectionView.register(HostCell.self, forCellWithReuseIdentifier: cellIdentifier)
        
        let dataSource = Coordinator.DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let hostCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? HostCell
            hostCell?.hostedCell = cell(indexPath, item)
            return hostCell
        }
        context.coordinator.dataSource = dataSource
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            let coordinator = context.coordinator
            if !coordinator.registeredSupplementaryViewKinds.contains(kind) {
                collectionView.register(HostSupplementaryView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: supplementaryViewIdentifier)
                coordinator.registeredSupplementaryViewKinds.append(kind)
            }
            
            guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: supplementaryViewIdentifier, for: indexPath) as? HostSupplementaryView else { return nil }
            view.hostedSupplementaryView = supplementaryView(kind, indexPath)
            return view
        }
        
        reloadData(in: collectionView, context: context)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        if parentTabScrollingEnabled {
            uiView.play_nearestViewController?.tabBarObservedScrollView = uiView
        }
        
        reloadData(in: uiView, context: context, animated: true)
    }
}
