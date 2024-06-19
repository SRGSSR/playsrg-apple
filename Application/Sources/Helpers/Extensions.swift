//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import Foundation
import SRGAppearanceSwift
import SRGDataProviderCombine
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

func url(for image: SRGImage?, size: SRGImageSize) -> URL? {
    SRGDataProvider.current!.url(for: image, size: size)
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension Float {
    // See https://stackoverflow.com/a/31390678/760435
    var minimalRepresentation: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

extension String {
    static func placeholder(length: Int) -> String {
        String(repeating: " ", count: length)
    }

    static let loremIpsum: String = """
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

    static let loremIpsumWithSpacesAndNewLine: String = """
    \r\n   Lorem ipsum dolor sit amet.\r\n\r\n\rConsetetur sadipscing elitr, sed diam \
    nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.\r\n
    """

    func unobfuscated() -> String {
        components(separatedBy: .decimalDigits).joined()
    }

    var capitalizedFirstLetter: String {
        prefix(1).capitalized + dropFirst()
    }

    func heightOfString(usingFontStyle fontStyle: SRGFont.Style) -> CGFloat {
        sizeOfString(usingFontStyle: fontStyle).height
    }

    func widthOfString(usingFontStyle fontStyle: SRGFont.Style) -> CGFloat {
        sizeOfString(usingFontStyle: fontStyle).width
    }

    private func sizeOfString(usingFontStyle fontStyle: SRGFont.Style) -> CGSize {
        let font = SRGFont.font(fontStyle) as UIFont
        let attributes = [NSAttributedString.Key.font: font]
        let attributedString = NSAttributedString(string: self, attributes: attributes)
        return attributedString.size()
    }

    /*
     * Compact the string to not contain any empty lines or white spaces.
     */
    var compacted: String {
        replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
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

    func median() -> Element? where Element: FloatingPoint {
        guard !isEmpty else { return nil }

        let sortedSelf = sorted()
        let count = sortedSelf.count

        if count.isMultiple(of: 2) {
            return (sortedSelf[count / 2 - 1] + sortedSelf[count / 2]) / 2
        } else {
            return sortedSelf[count / 2]
        }
    }
}

extension Collection {
    /**
     *  Transform each item in a collection, providing an auto-increased index with each processed item.
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
     *  Transform each item in a collection (getting rid of `nil` items), providing an auto-increased index with each
     *  processed item.
     */
    func enumeratedCompactMap<T>(_ transform: (Self.Element, Int) throws -> T?) rethrows -> [T] {
        var index = 0
        return try compactMap { element in
            let transformedElement = try transform(element, index)
            index += 1
            return transformedElement
        }
    }

    /**
     *  Groups items from the receiver into an alphabetical list. Preserves the initial ordering in each group,
     *  and collects items starting with non-letter characters under '#'. If a group is present in the returned
     *  array the array of associated items is guaranteed to contain at least 1 item.
     */
    func groupedAlphabetically(by keyForElement: (Self.Element) throws -> (some StringProtocol)?) rethrows -> [(key: Character, value: [Self.Element])] {
        let dictionary = try [Character: [Self.Element]](grouping: self) { element in
            if let key = try keyForElement(element),
               let character = key.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).first, character.isLetter {
                character
            } else {
                "#"
            }
        }
        let hashGroup = dictionary["#"]
        return dictionary
            .filter { $0.key != "#" }
            .sorted { $0.key < $1.key }
            .appending(contentsOf: hashGroup.map { [(Character("#"), $0)] } ?? [])
    }
}

extension Sequence {
    /**
     *  Transform each items in a collection into a sequence and flattens the output, providing an auto-increased index with each processed item.
     */
    func enumeratedFlatMap<S>(_ transform: (Self.Element, Int) throws -> S) rethrows -> [S.Element] where S: Sequence {
        var index = 0
        return try flatMap { element in
            let transformedElement = try transform(element, index)
            index += 1
            return transformedElement
        }
    }
}

// Borrowed from https://www.swiftbysundell.com/articles/combine-self-cancellable-memory-management/
// TODO: Remove after tvOS media detail view refactoring
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
            if let label, !label.isEmpty {
                // FIXME: Accessibility hints are currently buggy with SwiftUI on tvOS. Applying a hint makes VoiceOver tell only the hint,
                //        forgetting about the label. Until this is fixed by Apple we must avoid applying hints on tvOS.
                #if os(tvOS)
                    accessibilityHidden(true)
                        .accessibilityElement()
                        .accessibilityLabel(label)
                        .accessibilityAddTraits(traits)
                #else
                    accessibilityHidden(true)
                        .accessibilityElement()
                        .accessibilityLabel(label)
                        .accessibilityHint(hint ?? "")
                        .accessibilityAddTraits(traits)
                #endif
            } else {
                accessibilityHidden(true)
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
            let hostController = UIHostingController(rootView: environment(\.horizontalSizeClass, UserInterfaceSizeClass(horizontalSizeClass)))
        #else
            let hostController = UIHostingController(rootView: self)
        #endif
        return hostController.sizeThatFits(in: size)
    }

    /**
     *  Read the size of a view and provides it to the specified closure.
     *
     *  Warning: Beware of recurisve layout issues when the closure itself triggers a view update.
     *
     *  Borrowed from https://www.fivestars.blog/articles/flexible-swiftui/
     */
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }

    /**
     *  Small helper to build a frame with a size.
     */
    func frame(size: CGSize, alignment: Alignment = .center) -> some View {
        frame(width: size.width, height: size.height, alignment: alignment)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value _: inout CGSize, nextValue _: () -> CGSize) {}
}

/**
 *  Available selection styles.
 */
enum SelectionAppearance {
    case dimmed // The view is dimmed.
    case transluscent // The view is slightly transluscent.
}

extension View {
    /**
     *  Adjust the selection appearance of the receiver, applying one of the available styles.
     */
    func selectionAppearance(_ appearance: SelectionAppearance = .dimmed, when selected: Bool, while editing: Bool = false) -> some View {
        Group {
            if (!editing && selected) || (editing && !selected) {
                switch appearance {
                case .dimmed:
                    overlay(Color.black.opacity(0.5))
                case .transluscent:
                    opacity(0.5)
                }
            } else {
                self
            }
        }
    }
}

// See https://stackoverflow.com/questions/61552497/uitableviewheaderfooterview-with-swiftui-content-getting-automatic-safe-area-ins
extension UIHostingController {
    public convenience init(rootView: Content, ignoreSafeArea: Bool) {
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
        } else {
            guard let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String else { return }
            guard let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0) else { return }

            if let method = class_getInstanceMethod(UIView.self, #selector(getter: UIView.safeAreaInsets)) {
                let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in
                    .zero
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

    static func horizontal(layoutWidth: CGFloat, horizontalMargin: CGFloat = 0, spacing: CGFloat = 0, top: CGFloat = 0, bottom: CGFloat = 0, cellSizer: CellSizer) -> NSCollectionLayoutSection {
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

    static func grid(layoutWidth: CGFloat, horizontalMargin: CGFloat = 0, spacing: CGFloat = 0, top: CGFloat = 0, bottom: CGFloat = 0, cellSizer: CellSizer) -> NSCollectionLayoutSection {
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
            size.width * dimension
        } else if isFractionalHeight {
            size.height * dimension
        } else {
            dimension
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
        constrained(to: view.frame.size)
    }

    var previewSize: CGSize {
        constrained(to: Self.defaultSize)
    }
}

extension View {
    func horizontalSizeClass(_ sizeClass: UIUserInterfaceSizeClass) -> some View {
        #if os(iOS)
            return environment(\.horizontalSizeClass, UserInterfaceSizeClass(sizeClass))
        #else
            return self
        #endif
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
    private func sizingBehavior(of hostingController: UIHostingController<some Any>, for axis: NSLayoutConstraint.Axis) -> SizingBehavior {
        // Fit into the maximal allowed layout size to check which boundaries are adopted by the associated view
        let size = hostingController.sizeThatFits(in: UIView.layoutFittingExpandedSize)
        if axis == .vertical {
            return size.height == UIView.layoutFittingExpandedSize.height ? .expanding : .hugging
        } else {
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
    func applySizingBehavior(of hostingController: UIHostingController<some Any>, for axis: NSLayoutConstraint.Axis) {
        applySizingBehavior(sizingBehavior(of: hostingController, for: axis), for: axis)
    }

    /// Apply the same sizing behavior as the provided hosting controller in all directions (layout neutrality).
    func applySizingBehavior(of hostingController: UIHostingController<some Any>) {
        applySizingBehavior(of: hostingController, for: .horizontal)
        applySizingBehavior(of: hostingController, for: .vertical)
    }
}

extension UIViewController {
    func deselectItems(in collectionView: UICollectionView, animated: Bool) {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else { return }
        guard animated, let transitionCoordinator, transitionCoordinator.animate(alongsideTransition: { context in
            for indexPath in selectedIndexPaths {
                collectionView.deselectItem(at: indexPath, animated: context.isAnimated)
            }
        }, completion: { context in
            if context.isCancelled {
                for indexPath in selectedIndexPaths {
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }
            }
        })
        else {
            for indexPath in selectedIndexPaths {
                collectionView.deselectItem(at: indexPath, animated: animated)
            }
            return
        }
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }

    @ViewBuilder
    func play_scrollClipDisabled() -> some View {
        if #available(iOS 17, tvOS 17, *) {
            self.scrollClipDisabled()
        } else {
            self
        }
    }
}

extension UIApplication {
    /// Return the main window scene among all connected scenes, if any.
    @objc var mainWindowScene: UIWindowScene? {
        connectedScenes
            .filter { $0.delegate is SceneDelegate }
            .compactMap { $0 as? UIWindowScene }
            .first
    }

    /// Return the main key window among all connected scenes, if any.
    @objc var mainWindow: UIWindow? {
        mainWindowScene?.windows
            .first { $0.isKeyWindow }
    }

    /// Return the main scene delegate, if any.
    @objc var mainSceneDelegate: SceneDelegate? {
        mainWindowScene?.delegate as? SceneDelegate
    }

    /// Return the main top view controller, if any.
    @objc var mainTopViewController: UIViewController? {
        mainWindow?.play_topViewController
    }

    #if os(iOS)
        /// Return the main tab bar root controller, if any.
        @objc var mainTabBarController: TabBarController? {
            mainWindow?.rootViewController as? TabBarController
        }
    #endif
}

extension Locale {
    static let currentLanguageIdentifier: String = if #available(iOS 16, tvOS 16, *) {
        Locale.current.identifier(.bcp47)
    } else {
        Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    }
}

extension SRGAnalyticsLabels {
    @objc class var play_globalLabels: SRGAnalyticsLabels {
        let analyticsLabels = UserConsentHelper.srgAnalyticsLabels
        var customInfo: [String: String] = analyticsLabels.customInfo ?? [:]

        customInfo["navigation_app_language"] = Locale.currentLanguageIdentifier

        analyticsLabels.customInfo = customInfo
        return analyticsLabels
    }
}
