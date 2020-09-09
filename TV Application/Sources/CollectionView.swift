//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

private struct IsPressedKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    var isPressed: Bool {
        get { self[IsPressedKey.self] }
        set { self[IsPressedKey.self] = newValue }
    }
}

extension CollectionView {
    func synchronizeParentTabScrolling() -> some View {
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
     *  Host root view to broadcast button press information in the environment.
     */
    private struct HostCellRootView<Body: View>: View {
        let hostedView: Body
        @ObservedObject var hostCell: HostCell
        
        var body: some View {
            hostedView
                .environment(\.isPressed, hostCell.isPressed)
        }
    }
    
    /**
     *  `UICollectionView` cell hosting a `SwiftUI` view.
     */
    private class HostCell: UICollectionViewCell, ObservableObject {
        private var hostController: UIHostingController<HostCellRootView<Cell>>?
        
        @Published fileprivate var isPressed: Bool = false
        
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
                hostController = UIHostingController(rootView: HostCellRootView(hostedView: view, hostCell: self), ignoreSafeArea: true)
                if let hostView = hostController?.view {
                    hostView.frame = contentView.bounds
                    hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    contentView.addSubview(hostView)
                }
            }
        }
        
        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            super.pressesBegan(presses, with: event)
            
            for press in presses where press.type == .select {
                isPressed = true
            }
        }
        
        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            super.pressesEnded(presses, with: event)
            
            for press in presses where press.type == .select {
                isPressed = false
            }
        }
        
        override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            super.pressesCancelled(presses, with: event)
            
            for press in presses where press.type == .select {
                isPressed = false
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
    
    private class FocusGuideBackgroundView: UICollectionReusableView {
        private class FocusGuide: UIFocusGuide {
            var section: Int? = nil
            weak var collectionView: UICollectionView? = nil
            
            private var visibleCells: [UICollectionViewCell] {
                guard let collectionView = collectionView else { return [] }
                let indexPaths = collectionView.indexPathsForVisibleItems.sorted().reversed().filter { $0.section == section }
                return indexPaths.map { collectionView.cellForItem(at: $0)! }
            }
            
            override var preferredFocusEnvironments: [UIFocusEnvironment]! {
                get { visibleCells }
                set {}
            }
        }
        
        var section: Int? {
            get {
                focusGuide.section
            }
            set {
                focusGuide.section = newValue
            }
        }
        
        var collectionView: UICollectionView? {
            get {
                focusGuide.collectionView
            }
            set {
                focusGuide.collectionView = newValue
            }
        }
        
        private weak var focusGuide: FocusGuide!
        
        private func createFocusGuide() {
            let focusGuide = FocusGuide()
            addLayoutGuide(focusGuide)
            self.focusGuide = focusGuide
            
            NSLayoutConstraint.activate([
                focusGuide.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                focusGuide.heightAnchor.constraint(equalToConstant: 1),
                focusGuide.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                focusGuide.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            createFocusGuide()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            createFocusGuide()
        }
    }
    
    /**
     *  View coordinator.
     */
    class Coordinator: NSObject, UICollectionViewDelegate {
        fileprivate typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
        
        /// Data source for the collection view.
        fileprivate var dataSource: DataSource? = nil
        
        // Blocks from parent collection.
        fileprivate var sectionLayoutProvider: ((Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection)?
        fileprivate var onSelect: OnSelect?
        
        /// Hash of the data represented by the data source. Provides for a cheap way of checking when data changes.
        fileprivate var dataHash: Int? = nil
        
        /// Store whether the data source is currently empty.
        fileprivate var isEmpty: Bool = true
        
        /// Registered view kinds for supplementary views.
        fileprivate var registeredSupplementaryViewKinds: [String] = []
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if let onSelect = onSelect,
               let item = dataSource?.itemIdentifier(for: indexPath) {
                onSelect(indexPath, item)
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
            if let focusGuideBackgroundView = view as? FocusGuideBackgroundView {
                focusGuideBackgroundView.section = indexPath.section
                focusGuideBackgroundView.collectionView = collectionView
            }
        }
    }
    
    typealias OnSelect = (IndexPath, Item) -> Void
    
    /// Data displayed by the collection view.
    let rows: [CollectionRow<Section, Item>]
    
    /// Provider for the section layout.
    let sectionLayoutProvider: (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection
    
    /// Cell view builder.
    let cell: (IndexPath, Item) -> Cell
    
    /// Supplementary view builder.
    let supplementaryView: (String, IndexPath) -> SupplementaryView
    
    /// Selection action.
    fileprivate var onSelect: OnSelect? = nil
    
    /// If `true`, tabs move in sync with the collection.
    fileprivate var parentTabScrollingEnabled: Bool = false
    
    /**
     *  Create a collection view displaying the specified data with cells delivered by the provided builder.
     */
    init(rows: [CollectionRow<Section, Item>],
         sectionLayoutProvider: @escaping (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection,
         @ViewBuilder cell: @escaping (IndexPath, Item) -> Cell,
         @ViewBuilder supplementaryView: @escaping (String, IndexPath) -> SupplementaryView) {
        self.rows = rows
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
        let focusGuideIdentifier = "focusGuide"
        
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let section = context.coordinator.sectionLayoutProvider!(sectionIndex, layoutEnvironment)
            let focusGuide = NSCollectionLayoutDecorationItem.background(elementKind: focusGuideIdentifier)
            section.decorationItems.append(focusGuide)
            return section
        }
        layout.register(FocusGuideBackgroundView.self, forDecorationViewOfKind: focusGuideIdentifier)
        return layout
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
        
        let dataSource = Coordinator.DataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
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
        
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        let coordinator = context.coordinator
        coordinator.sectionLayoutProvider = self.sectionLayoutProvider
        coordinator.onSelect = self.onSelect
        
        if parentTabScrollingEnabled {
            uiView.play_nearestViewController?.tabBarObservedScrollView = uiView
        }
        
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

extension CollectionView {
    func onSelect(_ onSelect: @escaping OnSelect) -> Self {
        var collectionView = self
        collectionView.onSelect = onSelect
        return collectionView
    }
}
