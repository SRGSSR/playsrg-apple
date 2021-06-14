//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

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
            Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et
            dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
            Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet,
            consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat,
            sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no
            sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr,
            sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero
            eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est
            Lorem ipsum dolor sit amet.
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
}

extension SRGImageMetadata {
    func imageUrl(for scale: ImageScale, with type: SRGImageType = .default) -> URL? {
        return imageURL(for: .width, withValue: SizeForImageScale(scale).width, type: type)
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
    func accessibilityElement<S>(label: S?, hint: S? = nil, traits: AccessibilityTraits = []) -> some View where S: StringProtocol {
        // FIXME: Accessibility hints are currently buggy with SwiftUI on tvOS. Applying a hint makes VoiceOver tell only the hint,
        //        forgetting about the label. Until this is fixed by Apple we must avoid applying hints on tvOS.
        #if os(tvOS)
        return accessibilityElement()
            .accessibilityOptionalLabel(label)
            .accessibilityAddTraits(traits)
        #else
        return accessibilityElement()
            .accessibilityOptionalLabel(label)
            .accessibilityOptionalHint(hint)
            .accessibilityAddTraits(traits)
        #endif
    }
    
    private func accessibilityOptionalLabel<S>(_ label: S?) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S: StringProtocol {
        return accessibilityLabel(label ?? "")
    }
    
    private func accessibilityOptionalHint<S>(_ hint: S?) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S: StringProtocol {
        return accessibilityHint(hint ?? "")
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
    typealias CellSizer = ((layoutWidth: CGFloat, spacing: CGFloat)) -> NSCollectionLayoutSize
    
    static func horizontal(layoutWidth: CGFloat, spacing: CGFloat = 0, top: CGFloat = 0, bottom: CGFloat = 0, cellSizer: CellSizer) -> NSCollectionLayoutSection {
        let horizontalMargin = constant(iOS: 2 * spacing, tvOS: 0)
        
        let effectiveLayoutWidth = layoutWidth - 2 * horizontalMargin
        let cellSize = cellSizer((effectiveLayoutWidth, spacing))
        
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
        let cellSize = cellSizer((effectiveLayoutWidth, spacing))
        
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
