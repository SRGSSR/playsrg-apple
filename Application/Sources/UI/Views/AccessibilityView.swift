//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

@objc protocol AccessibilityViewDelegate: AnyObject {
    func labelForAccessibilityView(_ accessibilityView: AccessibilityView) -> String?
    func hintForAccessibilityView(_ accessibilityView: AccessibilityView) -> String?
}

@objc class AccessibilityView: UIView {
    @IBOutlet private weak var delegate: AccessibilityViewDelegate?

    public func setDelegate(_ delegate: AccessibilityViewDelegate?) {
        self.delegate = delegate
    }

    override var isAccessibilityElement: Bool {
        get {
            true
        }
        set {}
    }

    override var accessibilityLabel: String? {
        get {
            delegate?.labelForAccessibilityView(self)
        }
        set {}
    }

    override var accessibilityHint: String? {
        get {
            delegate?.hintForAccessibilityView(self)
        }
        set {}
    }
}
