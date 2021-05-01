//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import Foundation
import SwiftUI

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

extension String {
    static func placeholder(length: Int) -> String {
        return String(repeating: " ", count: length)
    }
    
    var capitalizedFirstLetter: String {
        return prefix(1).capitalized + dropFirst()
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
    func accessibilityOptionalLabel<S>(_ label: S?) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol {
        return accessibilityLabel(label ?? "")
    }
    
    func accessibilityOptionalHint<S>(_ hint: S?) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol {
        return accessibilityHint(hint ?? "")
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
    static func horizontal(cellSize: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(cellSize.width), heightDimension: .absolute(cellSize.height))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        return NSCollectionLayoutSection(group: group)
    }
    
    static func grid(cellSize: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(cellSize.width), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(cellSize.height))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        return NSCollectionLayoutSection(group: group)
    }
}
