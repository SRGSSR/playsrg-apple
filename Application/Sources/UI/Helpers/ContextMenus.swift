//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

enum ContextMenu {
    static func configuration(for item: Content.Item) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let action = UIAction(title: "Test") { _ in
                print("--> Action")
            }
            return UIMenu(title: "Menu", children: [action])
        }
    }
}
