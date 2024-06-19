//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

@objc protocol ProfileSectionSettable {
    var title: String? { get set }
}

extension UITableView {
    final class ProfileSectionTableViewHeaderView: HostTableViewHeaderFooterView<ProfileSectionHeaderView>, ProfileSectionSettable {
        var title: String? {
            didSet {
                if let title {
                    content = ProfileSectionHeaderView(title: title)
                } else {
                    content = nil
                }
            }
        }
    }

    private static let reuseIdentifier = "ProfileSectionHeaderView"

    @objc func registerReusableProfileSectionHeader() {
        register(ProfileSectionTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: Self.reuseIdentifier)
    }

    @objc func dequeueReusableProfileSectionHeader() -> UITableViewHeaderFooterView & ProfileSectionSettable {
        dequeueReusableHeaderFooterView(withIdentifier: UITableView.reuseIdentifier) as! ProfileSectionTableViewHeaderView
    }
}
