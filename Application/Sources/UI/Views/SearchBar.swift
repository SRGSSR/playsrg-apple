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
    override func layoutSubviews() {
        super.layoutSubviews()
        showsCancelButton = false
    }
}
