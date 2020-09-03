//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

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
     *  Cell host root view. Only required to fix safe area insets otherwise applied to `UIHostingController` in cells.
     */
    private struct HostRootView<Body: View>: View {
        let hostedView: Body
        
        var body: some View {
            hostedView.ignoresSafeArea(.all)
        }
    }
    
    /**
     *  `UICollectionView` cell hosting a `SwiftUI` view.
     */
    private class HostCell: UICollectionViewCell {
        private var hostController: UIHostingController<HostRootView<Cell>>?
        
        override func prepareForReuse() {
            if let hostView = hostController?.view {
                hostView.removeFromSuperview()
            }
        }
        
        override var canBecomeFocused: Bool {
            return false
        }
        
        var hostedCell: Cell? {
            willSet {
                // Creating a `UIHostingController` is cheap.
                guard let view = newValue else { return }
                hostController = UIHostingController(rootView: HostRootView(hostedView: view))
                if let hostView = hostController?.view {
                    hostView.frame = contentView.bounds
                    hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    contentView.addSubview(hostView)
                }
            }
        }
    }
    
    private class HostSupplementaryView: UICollectionReusableView {
        private var hostController: UIHostingController<HostRootView<SupplementaryView>>?
        
        override func prepareForReuse() {
            if let hostView = hostController?.view {
                hostView.removeFromSuperview()
            }
        }
        
        var hostedSupplementaryView: SupplementaryView? {
            willSet {
                // Creating a `UIHostingController` is cheap.
                guard let view = newValue else { return }
                hostController = UIHostingController(rootView: HostRootView(hostedView: view))
                if let hostView = hostController?.view {
                    hostView.frame = self.bounds
                    hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.addSubview(hostView)
                }
            }
        }
    }
    
    /**
     *  View coordinator.
     */
    class Coordinator {
        fileprivate typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
        
        /// Data source for the collection view.
        fileprivate var dataSource: DataSource? = nil
        
        var sectionLayoutProvider: ((Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection)?
        
        /// Hash of the data represented by the data source. Provides for a cheap way of checking when data changes.
        fileprivate var dataHash: Int? = nil
        
        /// Store whether the data source is currently empty.
        fileprivate var isEmpty: Bool = true
        
        /// Registered view identifiers for supplementary views.
        var registeredSupplementaryViewIdentifiers: [String] = []
    }
    
    /// Data displayed by the collection view.
    let rows: [CollectionRow<Section, Item>]
    
    /// Provider for the section layout.
    let sectionLayoutProvider: (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection
    
    /// Cell view builder.
    let cellBuilder: (IndexPath, Item) -> Cell
    
    /// Supplementary view builder
    let supplementaryViewBuilder: (String, IndexPath) -> SupplementaryView
    
    /**
     *  Create a collection view displaying the specified data with cells delivered by the provided builder.
     */
    init(rows: [CollectionRow<Section, Item>],
         sectionLayoutProvider: @escaping (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection,
         @ViewBuilder cellBuilder: @escaping (IndexPath, Item) -> Cell,
         @ViewBuilder supplementaryViewBuilder: @escaping (String, IndexPath) -> SupplementaryView) {
        self.rows = rows
        self.sectionLayoutProvider = sectionLayoutProvider
        self.cellBuilder = cellBuilder
        self.supplementaryViewBuilder = supplementaryViewBuilder
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
    
    // MARK: - UIViewRepresentable implementation
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let cellIdentifier = "hostCell"
        let supplementaryViewIdentifier = "hostSupplementaryView"
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout(context: context))
        collectionView.register(HostCell.self, forCellWithReuseIdentifier: cellIdentifier)
        
        let dataSource = Coordinator.DataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? HostCell
            cell?.hostedCell = cellBuilder(indexPath, item)
            return cell
        }
        context.coordinator.dataSource = dataSource
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            let coordinator = context.coordinator
            if !coordinator.registeredSupplementaryViewIdentifiers.contains(kind) {
                collectionView.register(HostSupplementaryView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: supplementaryViewIdentifier)
                coordinator.registeredSupplementaryViewIdentifiers.append(kind)
            }
            
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: supplementaryViewIdentifier, for: indexPath) as? HostSupplementaryView
            view?.hostedSupplementaryView = supplementaryViewBuilder(kind, indexPath)
            return view
        }
        
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        let coordinator = context.coordinator
        coordinator.sectionLayoutProvider = self.sectionLayoutProvider
        
        guard let dataSource = coordinator.dataSource else { return }
        
        // This method is called when the data changes, but also when the environment changes (rotation, focus change,
        // etc.). To ensure costly refreshes are only performed when the data changes, we store a hash of the data
        // which can be cheaply checked for changes.
        let dataHash = rows.hashValue
        if coordinator.dataHash != dataHash {
            let animated = !coordinator.isEmpty && !rows.isEmpty
            dataSource.apply(snapshot(), animatingDifferences: animated)
            coordinator.dataHash = dataHash
        }
    }
}

