//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Collections
import Combine
import Foundation
import SwiftUI

func constant<T>(iOS: T, tvOS: T) -> T {
    #if os(tvOS)
    return tvOS
    #else
    return iOS
    #endif
}

/**
 *  Unique items: remove duplicated items. Items must not appear more than one time in the same row.
 *
 *  Idea borrowed from https://www.hackingwithswift.com/example-code/language/how-to-remove-duplicate-items-from-an-array
 */
func removeDuplicates<T: Hashable>(in items: [T]) -> [T] {
    var itemDictionnary = [T: Bool]()
    
    return items.filter {
        let isNew = itemDictionnary.updateValue(true, forKey: $0) == nil
        if !isNew {
            PlayLogWarning(category: "duplicates", message: "A duplicate item has been removed: \($0)")
        }
        return isNew
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

extension String {
    static func placeholder(length: Int) -> String {
        return String(repeating: " ", count: length)
    }
    
    static var loremIpsum: String {
        return """
            Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et \
            dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. \
            Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, \
            consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, \
            sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no \
            sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, \
            sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero \
            eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est. \
            Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et \
            dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. \
            Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, \
            consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, \
            sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no \
            sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, \
            sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero \
            eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est. \
            Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et \
            dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. \
            Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, \
            consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, \
            sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no \
            sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, \
            sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero \
            eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est.
            """
    }
    
    var capitalizedFirstLetter: String {
        return prefix(1).capitalized + dropFirst()
    }
}

extension Array {
    func appending(_ newElement: Element) -> Array {
        var array = self
        array.append(newElement)
        return array
    }
    
    func appending<S>(contentsOf newElements: S) -> Array where Element == S.Element, S: Sequence {
        var array = self
        array.append(contentsOf: newElements)
        return array
    }
    
    subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else { return nil }
        return self[index]
    }
}

extension Collection {
    /**
     *  Apply a transform to each item in a collection, providing an auto-increased index with each processed item.
     */
    func enumeratedMap<T>(_ transform: (Self.Element, Int) throws -> T) rethrows -> [T] {
        var index = 0
        return try map { element in
            let transformedElement = try transform(element, index)
            index += 1
            return transformedElement
        }
    }
    
    /**
     *  Groups items from the receiver into an alphabetical dictionary (whose keys are letters in alphabetical order).
     *  Preserves the initial ordering in each group. Group items starting with no letter under '#'.
     */
    func groupedAlphabetically<S>(by keyForElement: (Self.Element) throws -> S?) rethrows -> OrderedDictionary<Character, [Self.Element]> where S: StringProtocol {
        return try OrderedDictionary<Character, [Self.Element]>(grouping: self) { element in
            if let key = try keyForElement(element),
               let character = key.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).first, character.isLetter {
                return character
            }
            else {
                return "#"
            }
        }
    }
}

extension SRGImageMetadata {
    func imageUrl(for scale: ImageScale, with type: SRGImageType = .default) -> URL? {
        return imageURL(for: .width, withValue: SizeForImageScale(scale, type).width, type: type)
    }
}

// Borrowed from https://www.swiftbysundell.com/articles/combine-self-cancellable-memory-management/
extension Publisher where Failure == Never {
    func weakAssign<T: AnyObject>(to keyPath: ReferenceWritableKeyPath<T, Output>, on object: T) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}

extension View {
    /**
     *  Configure accessibility settings. If no label is provided the item will not be enabled for accessibility.
     */
    func accessibilityElement<S>(label: S?, hint: S? = nil, traits: AccessibilityTraits = []) -> some View where S: StringProtocol {
        Group {
            if let label = label, !label.isEmpty {
                // FIXME: Accessibility hints are currently buggy with SwiftUI on tvOS. Applying a hint makes VoiceOver tell only the hint,
                //        forgetting about the label. Until this is fixed by Apple we must avoid applying hints on tvOS.
                #if os(tvOS)
                accessibilityElement()
                    .accessibilityLabel(label)
                    .accessibilityAddTraits(traits)
                #else
                accessibilityElement()
                    .accessibilityLabel(label)
                    .accessibilityHint(hint ?? "")
                    .accessibilityAddTraits(traits)
                #endif
            }
            else {
                accessibility(hidden: true)
            }
        }
    }
    
    /**
     *  Calculate the size of a SwiftUI view provided with some parent size, and for the specified horizontal size class.
     *
     *  Most useful for views with hugging behavior in at least one direction. Expanding views in some direction takes
     *  all the provided space in this direction.
     */
    func adaptiveSizeThatFits(in size: CGSize, for horizontalSizeClass: UIUserInterfaceSizeClass) -> CGSize {
        #if os(iOS)
        let hostController = UIHostingController(rootView: self.environment(\.horizontalSizeClass, UserInterfaceSizeClass(horizontalSizeClass)))
        #else
        let hostController = UIHostingController(rootView: self)
        #endif
        return hostController.sizeThatFits(in: size)
    }
}

/**
 *  Available selection styles.
 */
enum SelectionAppearance {
    case dimmed                 // The view is dimmed.
    case transluscent           // The view is slightly transluscent.
}

extension View {
    /**
     *  Adjust the selection appearance of the receiver, applying one of the available styles.
     */
    func selectionAppearance(_ appearance: SelectionAppearance = .dimmed, when selected: Bool, while editing: Bool = false) -> some View {
        return Group {
            if (!editing && selected) || (editing && !selected) {
                switch appearance {
                case .dimmed:
                    overlay(Color.black.opacity(0.5))
                case .transluscent:
                    self.opacity(0.5)
                }
            }
            else {
                self
            }
        }
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

extension NSCollectionLayoutSection {
    typealias CellSizer = (_ layoutWidth: CGFloat, _ spacing: CGFloat) -> NSCollectionLayoutSize
    
    static func horizontal(layoutWidth: CGFloat, spacing: CGFloat = 0, top: CGFloat = 0, bottom: CGFloat = 0, cellSizer: CellSizer) -> NSCollectionLayoutSection {
        let horizontalMargin = constant(iOS: 2 * spacing, tvOS: 0)
        
        let effectiveLayoutWidth = layoutWidth - 2 * horizontalMargin
        let cellSize = cellSizer(effectiveLayoutWidth, spacing)
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: cellSize.widthDimension, heightDimension: cellSize.heightDimension)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: top, leading: horizontalMargin, bottom: bottom, trailing: horizontalMargin)
        return section
    }
    
    static func grid(layoutWidth: CGFloat, spacing: CGFloat = 0, top: CGFloat = 0, bottom: CGFloat = 0, cellSizer: CellSizer) -> NSCollectionLayoutSection {
        let horizontalMargin = constant(iOS: 2 * spacing, tvOS: 0)
        
        let effectiveLayoutWidth = layoutWidth - 2 * horizontalMargin
        let cellSize = cellSizer(effectiveLayoutWidth, spacing)
        
        let itemSize = NSCollectionLayoutSize(widthDimension: cellSize.widthDimension, heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: cellSize.heightDimension)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: top, leading: horizontalMargin, bottom: bottom, trailing: horizontalMargin)
        return section
    }
}

extension NSCollectionLayoutDimension {
    func constrained(to size: CGSize) -> CGFloat {
        if isFractionalWidth {
            return size.width * dimension
        }
        else if isFractionalHeight {
            return size.height * dimension
        }
        else {
            return dimension
        }
    }
}

extension NSCollectionLayoutSize {
    private static let defaultSize: CGSize = constant(iOS: CGSize(width: 750, height: 1334), tvOS: CGSize(width: 1920, height: 1080))
    
    @objc func constrained(to size: CGSize) -> CGSize {
        let width = widthDimension.constrained(to: size)
        let height = heightDimension.constrained(to: size)
        return CGSize(width: width, height: height)
    }
    
    @objc func constrained(by view: UIView) -> CGSize {
        return constrained(to: view.frame.size)
    }
    
    var previewSize: CGSize {
        return constrained(to: Self.defaultSize)
    }
}

extension UIView {
    /// Sizing behaviors
    enum SizingBehavior {
        /// The view matches the size of its content.
        case hugging
        /// The view takes as much space as offered.
        case expanding
    }
    
    /// Probe some hosting controller to determine the behavior of its SwiftUI view in some direction.
    private func sizingBehavior<T>(of hostingController: UIHostingController<T>, for axis: NSLayoutConstraint.Axis) -> SizingBehavior {
        // Fit into the maximal allowed layout size to check which boundaries are adopted by the associated view
        let size = hostingController.sizeThatFits(in: UIView.layoutFittingExpandedSize)
        if axis == .vertical {
            return size.height == UIView.layoutFittingExpandedSize.height ? .expanding : .hugging
        }
        else {
            return size.width == UIView.layoutFittingExpandedSize.width ? .expanding : .hugging
        }
    }
    
    /// Apply the specified sizing behavior in some direction.
    func applySizingBehavior(_ sizingBehavior: SizingBehavior, for axis: NSLayoutConstraint.Axis) {
        switch sizingBehavior {
        case .hugging:
            setContentHuggingPriority(.required, for: axis)
            setContentCompressionResistancePriority(.required, for: axis)
        case .expanding:
            setContentHuggingPriority(UILayoutPriority(0), for: axis)
            setContentCompressionResistancePriority(UILayoutPriority(0), for: axis)
        }
    }
    
    /// Apply the specified sizing behavior in all directions.
    func applySizingBehavior(_ sizingBehavior: SizingBehavior) {
        applySizingBehavior(sizingBehavior, for: .horizontal)
        applySizingBehavior(sizingBehavior, for: .vertical)
    }
    
    /// Apply the same sizing behavior as the provided hosting controller in some directions (layout neutrality).
    func applySizingBehavior<T>(of hostingController: UIHostingController<T>, for axis: NSLayoutConstraint.Axis) {
        applySizingBehavior(sizingBehavior(of: hostingController, for: axis), for: axis)
    }
    
    /// Apply the same sizing behavior as the provided hosting controller in all directions (layout neutrality).
    func applySizingBehavior<T>(of hostingController: UIHostingController<T>) {
        applySizingBehavior(of: hostingController, for: .horizontal)
        applySizingBehavior(of: hostingController, for: .vertical)
    }
}

extension UIViewController {
    func deselectItems(in collectionView: UICollectionView, animated: Bool) {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else { return }
        guard animated, let transitionCoordinator = transitionCoordinator, transitionCoordinator.animate(alongsideTransition: { context in
                selectedIndexPaths.forEach { indexPath in
                    collectionView.deselectItem(at: indexPath, animated: context.isAnimated)
                }
            }, completion: { context in
                if context.isCancelled {
                    selectedIndexPaths.forEach { indexPath in
                        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    }
                }
            })
        else {
            selectedIndexPaths.forEach { indexPath in
                collectionView.deselectItem(at: indexPath, animated: animated)
            }
            return
        }
    }
}
