//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import UIKit

/**
 *  Simple search bar without cancel button and with Play look & feel.
 *
 *  See https://stackoverflow.com/a/9727189/760435
 */
final class SearchBar: UISearchBar {
    @objc static func setup() {
        let appearance = UITextField.appearance(whenContainedInInstancesOf: [self])
        appearance.defaultTextAttributes = [
            .font: SRGFont.font(family: .text, weight: .regular, size: 18) as UIFont
        ]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        showsCancelButton = false
    }
}
