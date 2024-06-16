//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//
import UIKit

@objc protocol ApplicationSectionInfoSettable {
    var applicationSectionInfo: ApplicationSectionInfo? { get set }
}

extension UITableView {
    final class ProfileTableViewCell: HostTableViewCell<ProfileCell>, ApplicationSectionInfoSettable {
        var applicationSectionInfo: ApplicationSectionInfo? {
            didSet {
                if let applicationSectionInfo {
                    content = ProfileCell(applicationSectioninfo: applicationSectionInfo)
                } else {
                    content = nil
                }
            }
        }
    }

    private static let reuseIdentifier = "ProfileCell"

    @objc func registerReusableProfileCell() {
        register(ProfileTableViewCell.self, forCellReuseIdentifier: Self.reuseIdentifier)
    }

    @objc func dequeueReusableProfileCell(for indexPath: IndexPath) -> UITableViewCell & ApplicationSectionInfoSettable {
        return dequeueReusableCell(withIdentifier: Self.reuseIdentifier, for: indexPath) as! ProfileTableViewCell
    }
}
