//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

/**
 *  Simple search bar without cancel button. See https://stackoverflow.com/a/9727189/760435
 */
final class SearchBar: UISearchBar {
    var textField: UITextField? {
        Self.textField(in: self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        showsCancelButton = false
    }

    private static func textField(in view: UIView) -> UITextField? {
        if let textField = view as? UITextField {
            return textField
        } else {
            for subview in view.subviews {
                if let textField = textField(in: subview) {
                    return textField
                }
            }
        }
        return nil
    }
}
