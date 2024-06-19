//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

/**
 *  A collection view applying a stronger deceleration rate to horizontally scrollable sections.
 *
 *  TODO: Remove if the compositional layout API is further improved (could be added to `UICollectionViewCompositionalLayoutConfiguration`
 *        in the future).
 */
@available(tvOS, unavailable)
class DampedCollectionView: UICollectionView {
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)

        if let scrollView = subview as? UIScrollView {
            Self.applySettings(to: scrollView)
        }
    }

    static func applySettings(to scrollView: UIScrollView) {
        guard let scrollViewClass = object_getClass(scrollView) else { return }

        scrollView.decelerationRate = .fast
        scrollView.alwaysBounceHorizontal = true

        let scrollViewSubclassName = String(cString: class_getName(scrollViewClass)).appending("_IgnoreSafeArea")
        if let viewSubclass = NSClassFromString(scrollViewSubclassName) {
            object_setClass(scrollView, viewSubclass)
        } else {
            guard let viewClassNameUtf8 = (scrollViewSubclassName as NSString).utf8String else { return }
            guard let scrollViewSubclass = objc_allocateClassPair(scrollViewClass, viewClassNameUtf8, 0) else { return }

            if let decelerationRateMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.decelerationRate)) {
                let setDecelerationRate: @convention(block) (AnyObject, UIScrollView.DecelerationRate) -> Void = { _, _ in
                    // Do nothing, only prevent value changes
                }
                class_addMethod(scrollViewSubclass, #selector(setter: UIScrollView.decelerationRate), imp_implementationWithBlock(setDecelerationRate), method_getTypeEncoding(decelerationRateMethod))
            }

            if let alwaysBounceHorizontalMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.alwaysBounceHorizontal)) {
                let setAlwaysBounceHorizontal: @convention(block) (AnyObject, Bool) -> Void = { _, _ in
                    // Do nothing, only prevent value changes
                }
                class_addMethod(scrollViewSubclass, #selector(setter: UIScrollView.alwaysBounceHorizontal), imp_implementationWithBlock(setAlwaysBounceHorizontal), method_getTypeEncoding(alwaysBounceHorizontalMethod))
            }

            objc_registerClassPair(scrollViewSubclass)
            object_setClass(scrollView, scrollViewSubclass)
        }
    }
}
